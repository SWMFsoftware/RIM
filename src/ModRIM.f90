
module ModRIM
  use ModSizeRIM
  use ModKind, ONLY: Real8_

  implicit none

  real :: Version = 0.1

  real :: Radius

  real, dimension(0:nLons+1,nLats) :: &
       Latitude, Longitude, Potential, AveE, Eflux, SigmaH, SigmaP, &
       dLatitude, dLongitude, SMX, SMY, SMZ, &
       SigmaEUVH, SigmaEUVP, SigmaScatH, SigmaScatP, SigmaStarH, SigmaStarP, &
       SigmaAurH, SigmaAurP, Sigma0, &
       OldPotential, Jr

  real, dimension(0:nLons+1,nLats) :: &
       SigmaThTh, SigmaThPs, SigmaPsPs, &
       dSigmaThTh_dLatitude, dSigmaThTh_dLongitude, &
       dSigmaThPs_dLatitude, dSigmaThPs_dLongitude, &
       dSigmaPsPs_dLatitude, dSigmaPsPs_dLongitude

  real, dimension(0:nLons+1,nLats) :: &
       SolverA, SolverB, SolverC, SolverD, SolverE

  real, allocatable :: AllLons(:)

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

  real (Real8_) :: StartTime, CurrentTime

  real, dimension(:,:), allocatable :: &
       LatitudeAll, LongitudeAll, PotentialAll, SigmaHAll, SigmaPAll, &
       LocalVar

  real :: cpcps = 0.0
  real :: cpcpn = 0.0

end module ModRIM
