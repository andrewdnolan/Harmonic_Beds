!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Prediction with sklearn SVR model in FORTRAN
!   https://scikit-learn.org/dev/modules/svm.html#regression
!   http://www.nic.funet.fi/index/elmer/doc/ElmerProgrammersTutorial.pdf
!
! .. math :: \hat y = \sum_{i \in SV}(\alpha_i - \alpha_i^*) K(x_i, x) + b
!
! where:
!     - $ \hat y $ is our prediction vector
!     - $ \alpha_i - \alpha_i^*$ are the dual coefficents solved for in sklearn
!     - $ K(x_i, x) $ is our kernerl
!         - we use a radial basis function for our kernel of the form:
!            .. math :: \exp(-\gamma \|x-x'\|^2)
!
! We might be able to do the reading more succinctly:
! https://stackoverflow.com/questions/37905759/save-numpy-array-as-binary-to-read-from-fortran
!
! Would also be good to wrap the RBF calculation within a function:
! https://stackoverflow.com/questions/26809412/fortran-pass-an-array-to-functions
!
! THIS WORKS!!!!
!   Now lets write it so that it can be called by ELMER/ICE
!
! Previously the offset has been done from the commandline. Now we could just use
! set $\Delta \dot b$ to offest the "intercept" of the SVR, this should be
! be equivalent to what we were doing previously.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


PROGRAM sklearn_svr
IMPLICIT NONE
INTEGER, parameter :: dp=kind(0.d0)
INTEGER            :: AllocateStatus
INTEGER            :: SV, NX
INTEGER            :: i
REAL(KIND=dp)      :: gamma, Delta_mb
REAL(KIND=dp),  ALLOCATABLE :: support_vectors(:,:), dual_coef(:,:), x_prime(:,:),&
                               Kernel(:,:), y_hat(:,:)
! Number of support vectors (i.e. how many points of the original traning set
! were selected by a SVM as significant and to be used in the regression)

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                  READ/DECLARE CONSTANTS
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
NX   = 0
! OPEN the x locations to make predictions file
OPEN(unit=20,file='./Data/SVR/test_zs.dat',status='old',action='read')
! READ the rows of the x locations to make predictions file
DO
  READ (20,*, END=10)
  NX = NX +1
END DO
! CLOSE the x locations to make predictions file
10 CLOSE(unit=20)

SV   = 0
! OPEN the x locations to make predictions file
OPEN(unit=30,file='./DATA/SVR/support_vectors.dat',status='old',action='read')
! READ the rows of the x locations to make predictions file
DO
  READ (30,*, END=15)
  SV = SV +1
END DO
! CLOSE the x locations to make predictions file
15 CLOSE(unit=30)

! write(*,*) NX
! write(*,*) ''
! write(*,*) SV

! gamma = -1.0e-05_dp         ! hyperprameter tunned by sklearn
! SV    = 1119                ! number of support vectors
! NX    = 7771                ! length of the prediction location vectors


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

NX = 1
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                  ALLOCATE ARRAYS AND READ .DAT FILES
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! ALLOCATE a column vector for x locations to make predictions
ALLOCATE( x_prime(NX,1), STAT = AllocateStatus)
IF (AllocateStatus /= 0) STOP "*** Not enough memory ***"
! OPEN the x locations to make predictions file
OPEN(unit=20,file='./Data/SVR/test_zs.dat',status='old',action='read')
! READ the rows of the x locations to make predictions file
DO i=2,NX
  READ (20,*) x_prime(i,1)
END DO
! CLOSE the x locations to make predictions file
CLOSE(unit=20)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! ALLOCATE a column vector for the support vectors
ALLOCATE(support_vectors(SV,1), STAT = AllocateStatus)
IF (AllocateStatus /= 0) STOP "*** Not enough memory ***"
! OPEN the support vector file
OPEN(unit=30,file='./DATA/SVR/support_vectors.dat',status='old',action='read')
! READ the rows of the support vectors file
DO i=1,SV
  READ (30,*) support_vectors(i,1)
END DO
! CLOSE the support vectors file
CLOSE(unit=30)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! ALLOCATE a row vector for the dual coefficentss
ALLOCATE( dual_coef(1,SV), STAT = AllocateStatus)
IF (AllocateStatus /= 0) STOP "*** Not enough memory ***"
! OPEN the support vector file
OPEN(unit=40,file='./Data/SVR/dual_coef.dat',status='old',action='read')
! READ the rows of the support vector file
DO i=1,SV
  READ (40,*) dual_coef(1,i)
END DO
! CLOSE the support vector file
CLOSE(unit=40)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! ALLOCATE a the prediction (column) vector
ALLOCATE( y_hat(1,NX), STAT = AllocateStatus)
IF (AllocateStatus /= 0) STOP "*** Not enough memory ***"
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! ALLOCATE a the kernel matrix to be populated below
ALLOCATE( Kernel(SV,NX), STAT = AllocateStatus)
IF (AllocateStatus /= 0) STOP "*** Not enough memory ***"
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                  Calculation time!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

! Calculate the RBF kernel
Kernel(:,:) = EXP(-1.0e-05_dp * ABS(SPREAD(support_vectors(:,1), 2, NX) - SPREAD(x_prime(:,1), 1, SV))**2.0_dp)

WRITE(*,*) ""
WRITE(*,*) "Shape of Support Vecotr (SPREAD)"
WRITE(*,*) SHAPE(SPREAD(support_vectors(:,1), 2, NX))
WRITE(*,*) ""
WRITE(*,*) "Shape of Support Vecotr"
WRITE(*,*) SHAPE(support_vectors)
WRITE(*,*) ""
WRITE(*,*) "Shape of x prime Vecotr"
WRITE(*,*) SHAPE(SPREAD(x_prime(:,1), 1, SV))
! Do the prediction! We could offset the \dot b here by adding our \Delta \dot b
! to the intercept
y_hat = MATMUL(dual_coef,Kernel) - 1.1858632_dp

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! DEALLOCATE ALLOCATES ARRAYS
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!write(*,*)  y_hat(:,1)
! ! output data into a file
! OPEN(50, file = './DATA/SVR/fortran_svr_prediction.dat', status='old')
! DO i = 1,NX
!    WRITE(50,*) x_prime(i,1), y_hat(i,1)
! END DO
! CLOSE(50)

DEALLOCATE(support_vectors)
DEALLOCATE(dual_coef)
DEALLOCATE(x_prime)
DEALLOCATE(Kernel)
DEALLOCATE(y_hat)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
END PROGRAM sklearn_svr
