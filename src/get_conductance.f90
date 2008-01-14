
subroutine get_conductance

  use ModRIM
  use ModParamRIM

  implicit none

  integer :: iError, iLon, iLat
  real    :: cosSZA(0:nLons+1,nLats)
  real    :: cosLimit, MeetingValueP, MeetingValueH
  real    :: f107p49, f107p53

  ! Empirical Dayside Conductance

  cosSZA = (SMX * cos(ThetaTilt) - SMZ * sin(ThetaTilt)) &
       / sqrt(SMX**2 + SMY**2 + SMZ**2)

  f107p53 = f107flux**0.53
  f107p49 = f107flux**0.49
  cosLimit = cos(70.0*cPi/180.0)
  MeetingValueP = f107p49*(0.34*cosLimit+0.93*sqrt(cosLimit))
  MeetingValueH = f107p53*(0.81*cosLimit+0.54*sqrt(cosLimit))

  where (cosSZA > 0)
     SigmaEUVH = f107p53*(0.81*cosSZA+0.54*sqrt(cosSZA))
     SigmaEUVP = f107p49*(0.34*cosSZA+0.93*sqrt(cosSZA))
     SigmaScatH = 1.0
     SigmaScatP = 0.5
  end where

  where (cosSZA < cosLimit)
     SigmaEUVH = &
          ( SigmaEUVH + &
            MeetingValueH * exp(-((cosSZA-cosLimit)**2.0)*15.0)) * 0.5
     SigmaEUVP = &
          ( SigmaEUVP + &
            MeetingValueP * exp(-((cosSZA-cosLimit)**2.0)*15.0)) * 0.5
  end where

  where (cosSZA <= 0)
     SigmaScatH = 1.00*(10.00**cosSZA)
     SigmaScatP = 0.50*(10.00**cosSZA)
  end where
  
  SigmaStarH = StarLightPedConductance*2.0
  SigmaStarP = StarLightPedConductance

  ! Empirical Aurora:

  if (nEmpiricalLats > 0) then
     
     call IO_GetAveE(EmpiricalAveE, iError)

     if (iError /= 0) then
        write(*,*) "Error : ", iError
        call stop_RIM("Stopping in advance_RIM, call to IO_GetAveE")
     endif

     call IO_GetEFlux(EmpiricalEFlux, iError)

     if (iError /= 0) then
        write(*,*) "Error : ", iError
        call stop_RIM("Stopping in advance_RIM, call to IO_GetEFlux")
     endif

     do iLon=0,nLons+1 
        nEmpiricalLats = 1
        do iLat=1,nLats
           if (abs(Latitude(iLon,iLat)) > HighLatBoundary) then
              AveE(iLon,iLat)      = EmpiricalAveE(iLon,nEmpiricalLats)
              EFlux(iLon,iLat)     = EmpiricalEFlux(iLon,nEmpiricalLats)
              nEmpiricalLats = nEmpiricalLats + 1
           endif
        enddo
     enddo

  endif

  SigmaAurH = 0.45*(AveE**0.85)*SigmaAurP
  SigmaAurP = SQRT(EFlux) * 40. * AveE / (16. + AveE**2)

  SigmaH = sqrt( SigmaEUVH**2 + SigmaScatH**2 + SigmaStarH**2 + SigmaAurH**2)
  SigmaP = sqrt( SigmaEUVP**2 + SigmaScatP**2 + SigmaStarP**2 + SigmaAurP**2)

  Sigma0 = 1000.0

end subroutine get_conductance
