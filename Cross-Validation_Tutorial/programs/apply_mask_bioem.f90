
!-------------------------------------------------------
! Program to select voxel from the model according to a mask
!-------------------------------------------------------
! JLR 12/10
! JLR 09/11 convert to simple 3D map bandpass filter 
!-------------------------------------------------------
PROGRAM MaskCreate
IMPLICIT NONE
! 3D volume and basic parameters !
INTEGER                           :: nx,ny,nz
REAL                              :: nlong
REAL, ALLOCATABLE                 :: map(:,:,:),mask(:,:,:)
!INTEGER, ALLOCATABLE              :: maskCOOR(:,:)  

! Parameters
REAL, PARAMETER                   :: pi = (3.1415926535897)

! File name informations
CHARACTER(80)                     :: inmap,maskfile,outmap,infsc,title
CHARACTER(80)                     :: format1

! File parameters
REAL                              :: dmin,dmax,dmean,cell(6)
INTEGER                           :: nxyz(3),nxyzst(3),mxyz(3),mode

! Pixel size
REAL                              :: psize
 
!Counters
INTEGER                           :: i,j,k,l,m
INTEGER                           :: sec,lin


INCLUDE 'fftw3.f'

!-------------------------------------------------
! get startup information 
!-------------------------------------------------

READ (5,*)  inmap, maskfile      ! input map
READ (5,*)  outmap               ! out map 
READ (5,*)  psize

! Data streams
! Stream 1 = inmap
! Stream 3 = sharpmap

!-----------------------------------------
! Open map 
!-----------------------------------------
CALL Imopen(1,inmap,"RO");
CALL Irdhdr(1,nxyz,mxyz,mode,dmin,dmax,dmean)
nx         = nxyz(1)
ny         = nxyz(2)
nz         = nxyz(3)

nlong=REAL(nx)
IF (REAL(ny)>nlong) nlong=REAL(ny)
IF (REAL(nz)>nlong) nlong=REAL(nz)


! !-----------------------------------------
! ! Open mask
! !-----------------------------------------



CALL Imopen(2,maskfile,"RO");
CALL Irdhdr(2,nxyz,mxyz,mode,dmin,dmax,dmean)
nx         = nxyz(1)
ny         = nxyz(2)
nz         = nxyz(3)

nlong=REAL(nx)
IF (REAL(ny)>nlong) nlong=REAL(ny)
IF (REAL(nz)>nlong) nlong=REAL(nz)

!-------------------------------------------------
! Allocate arrays
!-------------------------------------------------
! Volumes images
ALLOCATE (map(nx,ny,nz))    ; map=0
ALLOCATE (mask(nx,ny,nz))   ; mask=0


! -------------------------------------------------
! Extract Mask coordinates from .mrc file
! -------------------------------------------------
DO sec=1,nz
  DO lin=1,ny
    CALL Imposn(2,sec-1,lin-1) 
    CALL Irdlin (2,mask(:,lin,sec),*999)
  END DO 
END DO 
mask=INT(mask)

! -------------------------------------------------
! Extract intensities from model .mrc file
! -------------------------------------------------
DO sec=1,nz
  DO lin=1,ny
    CALL Imposn(1,sec-1,lin-1) 
    CALL Irdlin (1,map(:,lin,sec),*999)
  END DO 
END DO 
map=DBLE(map)

!-------------------------------------------------
! 
OPEN(unit=3,file=outmap)


l=1
DO i=1,nx
    DO j=1,ny
        Do k=1,nz
        
            IF(mask(i,j,k)==1 .AND. map(i,j,k)>0) THEN
                WRITE(3,5), DBLE((i-nx/2.0)*psize), DBLE((j-ny/2.0)*psize), DBLE((k-nz/2.0)*psize),2*psize, map(i,j,k)
                l=l+1 
            END IF
        END DO    
    END DO
!   IF (intensitymask(i) > 0.0) THEN
!    intensitymask(i)=intensity(i)
!    WRITE(3,5),intensity(i)
!   END IF
    
END DO


! 
! DO i=1,l-1
!    WRITE(3,5),maskCOOR(1,i),maskCOOR(2,i),maskCOOR(3,i)
! END DO
   
5 FORMAT(f8.3,1x,f8.3,1x,f8.3,1x,f6.3,1x,f11.9)

CLOSE(3)


PRINT *, "Number of voxels of the original model", SIZE(map)
PRINT *, "Number of voxels of the masked model" ,l-1


!-------------------------------------------------
! Close files and destroy plans
!-------------------------------------------------
CALL Imclose(1)
CALL Imclose(2)
PRINT *, "Output file: ", outmap
STOP "Normal termination of Apply_Mask program"
999 STOP "End of File Read Error"
END PROGRAM MaskCreate




! program test_any
!   logical l
!   l = any((/.true., .true., .true./))
!   print *, l
!   call section
!   contains
!     subroutine section
!       integer a(2,3), b(2,3)
!       a = 1
!       b = 1 MaskCreate/job001/mask.mrc
!       b(2,2) = 2
!       print *, any(a .eq. b, 1)
!       print *, any(a .eq. b, 2)
!     end subroutine section
! end program test_any
