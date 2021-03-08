FUNCTION getAccumulation(  Model, Node, InputArray) RESULT(accum)
  ! provides you with most Elmer functionality
  USE DefUtils
  ! saves you from stupid errors
  IMPLICIT NONE
  ! the external variables
  !----------------------------------------------------------------------------
  TYPE(Model_t) :: Model         ! the access point to everything about the model
  INTEGER       :: Node          ! the current Node number
  REAL(KIND=dp) :: InputArray(1) ! Contains the arguments passed to the function
  REAL(KIND=dp) :: accum         ! the result
  !----------------------------------------------------------------------------
  ! internal variables
  !----------------------------------------------------------------------------
  ! REAL(KIND=dp) :: lapserate, ela0, dElaDt, elaT, accumulationAtSl,&
  !      inittime, time, elevation, cutoff, offset
  INTEGER       :: SV, i, n, AllocateStatus, Nsurf
  LOGICAL       :: FirstTime=.TRUE., GotIt
  REAL(KIND=dp) :: elevation, Delta_mb, gamma, intercept
  REAL(KIND=dp), dimension(1,1) :: x_prime, y_hat
  REAL(KIND=dp), ALLOCATABLE    :: support_vectors(:,:), dual_coef(:,:), Kernel(:,:)

  ! Variables that only need to be read in once, are saved for future uses
  SAVE FirstTime, SV, support_vectors, dual_coef

  IF (FirstTime) THEN
    FirstTime=.FALSE.
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !                  READ/DECLARE CONSTANTS
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
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
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

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
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

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
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  ! first time loop done
  END IF

  !========Use pointers to access model constants===============================
  Delta_mb  = ListGetConstReal( Model % Constants, 'Mass Balance Offset', GotIt )
  IF (.NOT. GotIt) THEN
    CALL WARN('getAccumulation','Keyword >Mass Balance Offset< not found in >Constant< section')
    CALL WARN('getAccumulation','Taking default value >Mass Balance Offset< of 0.0 (m a^{-1})')
    Delta_mb = 0.0_dp
  END IF

  gamma     = ListGetConstReal( Model % Constants, 'gamma', GotIt )
  IF (.NOT. GotIt) THEN
     CALL FATAL('getAccumulation', '>gamma< not found in constants section')
  END IF

  intercept = ListGetConstReal( Model % Constants, 'intercept', GotIt )
  IF (.NOT. GotIt) THEN
     CALL FATAL('getAccumulation', '>intercept< not found in constants section')
  END IF
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  ! ALLOCATE a the kernel matrix to be populated below
  ALLOCATE( Kernel(SV, 1), STAT = AllocateStatus)
  IF (AllocateStatus /= 0) STOP "*** Not enough memory ***"
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  elevation = InputArray(1)

  ! Calculate the RBF kernel
  Kernel(:,1) = EXP(gamma * ABS( support_vectors(:,1)- SPREAD(elevation, 1, SV) )**2.0_dp)

  ! Do the prediction! We could offset the \dot b here by adding our \Delta \dot b
  ! to the intercept
  y_hat = MATMUL(dual_coef,Kernel) + intercept + Delta_mb

  accum = y_hat(1,1)
  ! WRITE (Message, '(A,E10.2,A,E10.2)')  "elevation=", elevation, "time=", time
  ! CALL INFO("getAccumulation", Message, Level=9)

  RETURN

END FUNCTION getAccumulation
