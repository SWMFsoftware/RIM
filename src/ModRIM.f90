!  Copyright (C) 2002 Regents of the University of Michigan, portions used with permission 
!  For more information, see http://csem.engin.umich.edu/tools/swmf

module ModRIM
  use ModSizeRIM
  use ModKind, ONLY: Real8_
  use ModNumConst, ONLY: cDegToRad

  implicit none

  real :: Version = 0.1

  real :: Radius

  real, dimension(2,0:nLons+1) :: OCFLB = 60.0 * cDegToRad
  real :: OCFLBBuffer = 10.0 * cDegToRad
  real :: MinLat = 0.0
  integer :: iMinLat = 0

  real, dimension(0:nLons+1,nLats) :: &
       Latitude, Longitude, Potential, AveE, Eflux, SigmaH, SigmaP, &
       dLatitude, dLongitude, SMX, SMY, SMZ, &
       SigmaEUVH, SigmaEUVP, SigmaScatH, SigmaScatP, SigmaStarH, SigmaStarP, &
       SigmaAurH, SigmaAurP, Sigma0, &
       OldPotential=0.0, Jr, OuterMagJr, InnerMagJr, IonoJr, &
       OuterMagInvB, OuterMagRho, OuterMagP, OuterMagT, &
       Area, InnerMagEFlux, InnerMagAveE, JouleHeating

  real, dimension(0:nLons+1,nLats) :: &
       SigmaThTh, SigmaThPs, SigmaPsPs, &
       dSigmaThTh_dLatitude, dSigmaThTh_dLongitude, &
       dSigmaThPs_dLatitude, dSigmaThPs_dLongitude, &
       dSigmaPsPs_dLatitude, dSigmaPsPs_dLongitude

  real, dimension(0:nLons+1,nLats) :: &
       SolverA, SolverB, SolverC, SolverD, SolverE

  real, dimension(:), allocatable :: d_I, e_I, f_I, e1_I, f1_I

  real, dimension(:,:), allocatable :: &
       EmpiricalLatitude, EmpiricalMLT, &
       EmpiricalAveE, EmpiricalEFlux, &
       EmpiricalPotential
  integer :: nEmpiricalLats, nLatsSolve

  logical :: IsTimeAccurate
  real :: ThetaTilt, DipoleStrength

  integer, dimension(7) :: TimeArray
  integer :: nSolve=0

  real (Real8_) :: StartTime, CurrentTime, OldTime

  real, dimension(:,:), allocatable :: &
       LatitudeAll, LongitudeAll, PotentialAll, SigmaHAll, SigmaPAll, &
       LocalVar, OuterMagJrAll, InnerMagJrAll, IonoJrAll, &
       OuterMagInvBAll, OuterMagRhoAll, OuterMagPAll, &
       OuterMagInvBAllR, OuterMagRhoAllR, OuterMagPAllR, OuterMagTAllR, &
       LatitudeAllR, &
       InnerMagEFluxAll, InnerMagAveEAll, JouleHeatingAll, AveEAll, EfluxAll

  real :: cpcps = 0.0
  real :: cpcpn = 0.0

  logical :: IsNewInput = .true.
  real :: LatBoundaryGm = 60.0

end module ModRIM
