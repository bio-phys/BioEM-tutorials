
!-------------------------------------------------------
! Bandpassmap_fftw (based on bfactor_cref)
!-------------------------------------------------------
! JLR 12/10
! JLR 09/11 convert to simple 3D map bandpass filter 
!-------------------------------------------------------
PROGRAM Bandpassmap_fftw
IMPLICIT NONE
! 3D volume and basic parameters !
INTEGER                           :: nx,ny,nz
REAL                              :: nlong
REAL, ALLOCATABLE                 :: map(:,:,:),sharpmap(:,:,:)
DOUBLE COMPLEX, ALLOCATABLE       :: workingvol(:,:,:)

! Parameters
REAL, PARAMETER                   :: pi = (3.1415926535897)

! File name informations
CHARACTER(150)                     :: inmap,outmap,infsc,title
CHARACTER(80)                     :: format1
INTEGER                           :: usefsc
! File parameters
REAL                              :: dmin,dmax,dmean,cell(6)
INTEGER                           :: nxyz(3),nxyzst(3),mxyz(3),mode

! FFTW arrays
DOUBLE PRECISION, ALLOCATABLE     :: vol_fftw(:,:,:)
DOUBLE COMPLEX, ALLOCATABLE       :: volc_fftw(:,:,:)
REAL*8                            :: plan3df,plan3dr

! CTF and other mask variables
REAL                              :: psize
REAL                              :: pshftr
REAL                              :: radius,rfrac
INTEGER                           :: bin
 
! Time variables
INTEGER                           :: now(3)


! Array markers
REAL                              :: kx,ky,kz
INTEGER                           :: kxvol,kyvol,kzvol
INTEGER                           :: kxarray,kyarray,kzarray,array,kxwrap,kywrap,kzwrap
INTEGER                           :: ksum 
INTEGER                           :: i,j,k
INTEGER                           :: vox,sec,lin
INTEGER                           :: part,xpos,ypos,kxpos,kypos,kzpos


! Cref
CHARACTER(80)                     :: jnk
INTEGER                           :: ring
REAL                              :: res
REAL                              :: rmax2,filter

! Variables to speed up code
INTEGER                           :: nxby2,nxby2plus1,nyby2,nyby2plus1,nzby2,nlongby2plus1
INTEGER                           :: nyby2plus2,nyby2minus1
DOUBLE PRECISION                  :: nxnyinv,nxnynzinv,ccnorm          !1/(nx*ny),

INCLUDE 'fftw3.f'
!INCLUDE '/afs/rzg/.cs/fftw/fftw-3.3.4/@sys/intel-15.0/impi-5.0/include/fftw3.f'

!-------------------------------------------------
! get startup information 
!-------------------------------------------------

READ (5,*)  inmap      ! input map
READ (5,*)  outmap
READ (5,*)  psize,rmax2

! Data streams
! Stream 1 = inmap
! Stream 3 = sharpmap

!-----------------------------------------
! Open map 
!-----------------------------------------
CALL Imopen(1,inmap,"RO")
CALL Irdhdr(1,nxyz,mxyz,mode,dmin,dmax,dmean)
nx         = nxyz(1)
ny         = nxyz(2)
nz         = nxyz(3)

nlong=REAL(nx)
IF (REAL(ny)>nlong) nlong=REAL(ny)
IF (REAL(nz)>nlong) nlong=REAL(nz)

nxnyinv=1/DBLE(nx*ny)
nxnynzinv=1/DBLE(nx*ny*nz)
nxby2=nx/2
nxby2plus1=nx/2 + 1
nyby2=ny/2
nyby2plus1=ny/2 + 1
nyby2plus2=ny/2 + 2
nyby2minus1=ny/2 - 1
nzby2=nz/2
nlongby2plus1=nlong/2+1
rmax2=(psize*nx)/rmax2 ! (put into pixel radius)


!-------------------------------------------------
! Allocate arrays
!-------------------------------------------------
! Volumes images
ALLOCATE (map(nx,ny,nz))                     ; map=0
ALLOCATE (sharpmap(nx,ny,nz))                ; sharpmap=0
ALLOCATE (workingvol(nxby2plus1,ny,nz))      ; workingvol=0


! Images
ALLOCATE (vol_fftw(nx,ny,nz))                ; vol_fftw=0
ALLOCATE (volc_fftw(nxby2plus1,ny,nz))       ; volc_fftw=0

!-------------------------------------------------
! Plan Fourier Transforms
!-------------------------------------------------
CALL Dfftw_plan_dft_r2c_3d(plan3df,nx,ny,nz,vol_fftw,volc_fftw,fftw_estimate)
CALL Dfftw_plan_dft_c2r_3d(plan3dr,nx,ny,nz,volc_fftw,vol_fftw,fftw_estimate)

!-------------------------------------------------
! Read in and Fourier transform map
!-------------------------------------------------
DO sec=1,nz
  DO lin=1,ny
    CALL Imposn(1,sec-1,lin-1) 
    CALL Irdlin (1,map(:,lin,sec),*999)
  END DO 
END DO 
vol_fftw=DBLE(map)
CALL Dfftw_execute(plan3df) 

!-------------------------------------------------
! Place map FT in working volume (i.e. origin at centre)
!-------------------------------------------------
DO kxarray=1,nxby2plus1!-1
  DO kyarray=1,ny
    DO kzarray=1,nz
      ksum=(kxarray+1)+(kyarray-1)+(kzarray-1)
      pshftr=1.0
      IF (MOD(ksum,2).ne.0) pshftr=-1.0
      kxwrap=kxarray
      IF (kyarray<nyby2)    kywrap=kyarray+nyby2plus1 
      IF (kyarray>=nyby2)   kywrap=kyarray-nyby2+1 
      IF (kzarray<nzby2)    kzwrap=kzarray+nzby2+1 
      IF (kzarray>=nzby2)   kzwrap=kzarray-nzby2+1 
      workingvol(kxarray,kyarray,kzarray)=volc_fftw(kxwrap,kywrap,kzwrap)*pshftr
    END DO
  END DO
END DO



!-------------------------------------------------
! Apply sharpen and Cref map
!-------------------------------------------------
DO kzarray=1,nz
  DO kyarray=1,ny
    DO kxarray=1,nxby2+1
       kxpos=kxarray-1
       kypos=kyarray-nyby2
       kzpos=kzarray-nzby2
       radius=SQRT(REAL(kxpos**2+kypos**2+kzpos**2))
       !write (*,*) radius
       IF (radius==0)  THEN
         workingvol(kxarray,kyarray,kzarray)=workingvol(kxarray,kyarray,kzarray)
       ELSE IF (radius>nxby2plus1) THEN
         workingvol(kxarray,kyarray,kzarray)=0
       ELSE
         IF (radius>rmax2) THEN
           filter=0
         ELSE
           filter=1
         END IF
         workingvol(kxarray,kyarray,kzarray)=workingvol(kxarray,kyarray,kzarray)*DBLE(filter)
       END IF
    END DO
  END DO
END DO

!-------------------------------------------------
! Place map FT in working volume (i.e. origin at centre)
!-------------------------------------------------
DO kxarray=1,nxby2plus1
  DO kyarray=1,ny
    DO kzarray=1,nz
      ksum=(kxarray+1)+(kyarray-1)+(kzarray-1)
      pshftr=1.0
      IF (MOD(ksum,2).ne.0) pshftr=-1.0
      kxwrap=kxarray
      IF (kyarray<nyby2)    kywrap=kyarray+nyby2plus1 
      IF (kyarray>=nyby2)   kywrap=kyarray-nyby2+1 
      IF (kzarray<nzby2)    kzwrap=kzarray+nzby2+1 
      IF (kzarray>=nzby2)   kzwrap=kzarray-nzby2+1 
      volc_fftw(kxwrap,kywrap,kzwrap)=workingvol(kxarray,kyarray,kzarray)*pshftr
    END DO
  END DO
END DO
CALL Dfftw_execute(plan3dr)
vol_fftw=vol_fftw*nxnynzinv
sharpmap=REAL(vol_fftw)

!-------------------------------------------------
! write out map
!-------------------------------------------------

WRITE (*,*) "Writing output map"
CALL Imopen(3,outmap,"unknown")
dmin = MINVAL(sharpmap)
dmax = MAXVAL(sharpmap)
dmean = SUM(sharpmap)/(nx*ny*nz)
title="  "
nxyz=(/nx,ny,nz/)
nxyzst=(/0,0,0/)
mxyz=(/nx,ny,nz/)
cell=(/nx*psize,ny*psize,nz*psize,90.0,90.0,90.0/)
WRITE (*,*) "Writing output map"
CALL Itrhdr(3,1)
CALL Ialsiz(3,nxyz,nxyzst)
CALL Ialsam(3,mxyz)
CALL Ialcel(3,cell)
CALL Iwrhdr(3,title,-1,dmin,dmax,dmean)
DO sec=1,nz
  DO lin=1,ny
    CALL Imposn(3,sec-1,lin-1) 
    CALL Iwrlin(3,sharpmap(:,lin,sec))
  END DO
END DO


!-------------------------------------------------
! Close files and destroy plans
!-------------------------------------------------
CALL Imclose(1)
CALL Imclose(3)
CALL Dfftw_destroy_plan(plan3df)
CALL Dfftw_destroy_plan(plan3dr)

STOP "Normal termination of Bandpassmap_fftw"
999 STOP "End of File Read Error"
END PROGRAM Bandpassmap_fftw


