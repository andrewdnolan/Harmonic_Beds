SUBROUTINE SurfBoundary( Model,Solver,dt,TransientSimulation )

  USE DefUtils
  USE SolverUtils
  USE ElementUtils

  IMPLICIT NONE
  !----------------------------------------------------------------------------
  ! the external variables
  !----------------------------------------------------------------------------
  TYPE(Model_t)              :: Model
  TYPE(Variable_t),  POINTER :: MB,TimeVar,Depth
  TYPE(Solver_t),    POINTER :: Solver
  TYPE(ValueList_t), POINTER :: SolverParams
  TYPE(Element_t),   POINTER :: Element
  INTEGER,           POINTER :: NodeIndexes(:)
  REAL(KIND=dp)              :: dt

  !----------------------------------------------------------------------------
  ! internal variables
  !----------------------------------------------------------------------------
  ! INTEGER :: n,i,j,nb,k,cont,Day,ierr=0,year,nb_surf,nb_vert
  ! REAL(KIND=dp) :: f, g, x, z, deg_pos,accu_ref,a,deg_jour_snow,surimposed_ice_fact,deg_jour_ice,precip_fact
  ! REAL(KIND=dp) :: accu,melt_local,accu_ice,melt,accusnow,accuice,z_precip,grad_accu,deg_jour,dt,T,alt,grad,seuil_precip
  ! REAL(KIND=dp) :: seuil_fonte, dP_fact, dt_scale,Tref,precip_fact_ref,alpha,Tmean,AccuMean,tsurf,T0,time,delta_tsurf,t_simu
  INTEGER       :: SV, i, n, AllocateStatus, Nsurf
  logical       :: found,GotIt,first_time=.TRUE.,TransientSimulation
  REAL(KIND=dp) :: x_prime, Delta_mb
  REAL(KIND=dp), DIMENSION(1,1) :: y_hat
  REAL(KIND=dp), ALLOCATABLE    :: support_vectors(:,:), dual_coef(:,:), Kernel(:,:)

  !----------------------------------------------------------------------------

  ! Variables that only need to be read in once, are saved for future uses
  SAVE first_time, SV, support_vectors, dual_coef

  IF (first_time) THEN
    first_time=.FALSE.
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !                  READ/DECLARE CONSTANTS
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    SV   = 0
    ! OPEN the x locations to make predictions file
    OPEN(unit=30,file='./DATA/SMB/SVR/support_vectors.dat',status='old',action='read')
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
    OPEN(unit=30,file='./DATA/SMB/SVR/support_vectors.dat',status='old',action='read')
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
    OPEN(unit=40,file='./Data/SMB/SVR/dual_coef.dat',status='old',action='read')
    ! READ the rows of the support vector file
    DO i=1,SV
      READ (40,*) dual_coef(1,i)
    END DO
    ! CLOSE the support vector file
    CLOSE(unit=40)
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    !========Use pointers to access model fields================================
    Depth => VariableGet( Model % Variables, 'Depth')

    !========Get number of surface node=========================================
    Nsurf = 0
    DO  n = 1, model % NumberOfNodes
      IF (Depth % Values (Depth % perm (n))==0.0) THEN
        Nsurf = Nsurf + 1
      END IF
    END DO
 ! first time loop done
  END IF

  !========Use pointers to access model constants===============================
  Delta_mb = ListGetConstReal( Model % Constants, 'Mass Balance Offset', GotIt )
  IF (.NOT. GotIt) THEN
    CALL WARN('SurfBoundary','Keyword >Mass Balance Offset< not found in >Constant< section')
    CALL WARN('SurfBoundary','Taking default value >Mass Balance Offset< of 0.0 (m a^{-1})')
    Delta_mb = 0.0_dp
  END IF

  !========Use pointers to access model fields==================================
  MB      => VariableGet(Model % Variables, 'Mass Balance')
  TimeVar => VariableGet(Model % Mesh % Variables, 'time' )
  Depth   => VariableGet( Model % Variables, 'Depth')

  ! !=======Allcate our vectors to store data=====================================
  ! ALLOCATE( x_prime(Nsurf,1), STAT = AllocateStatus)
  ! IF (AllocateStatus /= 0) STOP "*** Not enough memory ***"
  !
  ! ALLOCATE( y_hat(1,Nsurf),   STAT = AllocateStatus)
  ! IF (AllocateStatus /= 0) STOP "*** Not enough memory ***"

  ALLOCATE( Kernel(SV,1),  STAT = AllocateStatus)
  IF (AllocateStatus /= 0) STOP "*** Not enough memory ***"

  !========Get the elevation at boundary values=================================
  DO n = 1, model % NumberOfNodes
    IF (Depth % Values (Depth % perm (n))==0.0) THEN
      x_prime = model % nodes % y(n)

      Kernel(:,1) = EXP(-1.0e-05_dp * ABS( support_vectors(:,1) - &
                                            SPREAD(x_prime, 1, SV) )**2.0_dp)

      ! Do the prediction! We could offset the \dot b here by adding our \Delta \dot b
      ! to the intercept
      y_hat = MATMUL(dual_coef,Kernel) - 1.1858632_dp + Delta_mb

      MB % Values ( MB % perm (n) ) = y_hat(1,1)
    END IF
  END DO
END SUBROUTINE SurfBoundary
