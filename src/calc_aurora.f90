!  Copyright (C) 2002 Regents of the University of Michigan, portions used with permission 
!  For more information, see http://csem.engin.umich.edu/tools/swmf

subroutine calc_aurora

  use ModRIM
  use ModNumConst, only: cPi
  use ModProcIE
  use ModParamRIM, only: iConductanceModel

  implicit none

  ! Variables that have an 'H' stuck on the end are only defined for a
  ! hemisphere
  real, dimension(0:nLons+1,nLats/2) :: JrH, eFluxH, AveEH
  real, allocatable :: rhoH(:,:), pH(:,:), TH(:,:), InvBH(:,:), LatH(:,:)
  real, allocatable :: OCFLBH(:)
  integer :: iLon, iLat, iLR, iLonTo, iLonFrom, iLatGood

  allocate( &
       rhoH(0:nLonsAll+1,nLats/2), &
       pH(0:nLonsAll+1,nLats/2), &
       TH(0:nLonsAll+1,nLats/2), &
       InvBH(0:nLonsAll+1,nLats/2), &
       LatH(0:nLonsAll+1,nLats/2), &
       OCFLBH(0:nLonsAll+1))

  ! We need to basically work from the pole outwards when figuring out the
  ! auroral oval.  Since the iLat index goes from the pole out in the Southern
  ! hemisphere and the equator to pole in the North, we will reverse the North
  ! and call a single subroutine for both hemispheres.  So, we need to move the
  ! variables into a temporary place, call the routine, then move the results
  ! back into permanent variables.

  ! South
  do iLat = 1, nLats/2
     ! These variable could be mirrored in Longitude, so we need them over the
     ! whole domain
     RhoH(:,iLat)  = OuterMagRhoAllR(:,iLat)
     PH(:,iLat)    = OuterMagPAllR(:,iLat)
     TH(:,iLat)    = OuterMagTAllR(:,iLat)
     InvBH(:,iLat) = OuterMagInvBAllR(:,iLat)
     LatH(:,iLat)  = -LatitudeAllR(:,iLat)
     ! These variables we only need for local domain
     JrH(:,iLat)   = OuterMagJr(:,iLat)
  enddo

  if (iConductanceModel == 5) then
     call old_aurora(RhoH,PH,TH, JrH, InvBH, LatH, OCFLBH, eFluxH, AveEH)
  else
     call solve_for_aurora(RhoH,PH,TH, JrH, InvBH, LatH, OCFLBH, eFluxH, AveEH)
  endif
  do iLon = 0, nLons+1
     ! Need to shift longitudes
     iLonTo   = iLon
     iLonFrom = mod(iLon + iProc*nLons, nLons*nProc)
     if (iLonFrom == 0) iLonFrom = nLons*nProc
     OCFLB(1,iLonTo) = OCFLBH(iLonFrom)
  enddo

  ! Move results back into main variables

  do iLat = 1, nLats/2
     OuterMagRhoAllR(:,iLat) = RhoH(:,iLat)
     AveE(:,iLat)  = AveEH(:,iLat)
     eFlux(:,iLat) = eFluxH(:,iLat) 
     if (maxval(InnerMagAveE) > 0.0 .and. iConductanceModel == 7) then

        AveE(:,iLat) = &
          (EFluxH(:,iLat) + InnerMagEFlux(:,iLat)) / ( &
          EFluxH(:,iLat)/AveE(:,iLat) + &
          InnerMagEFlux(:,iLat)/InnerMagAveE(:,iLat)) 

        EFlux(:,iLat) = ( &
          EFluxH(:,iLat)/AveEH(:,iLat) + &
          InnerMagEFlux(:,iLat)/InnerMagAveE(:,iLat)) * AveE(:,iLat)

     endif
  enddo

  ! North
  do iLat = 1, nLats/2
     ! iLR = iLat Reversed (from North pole to equator)
     iLR = nLats-iLat+1
     RhoH(:,iLat)  = OuterMagRhoAllR(:,iLR)
     PH(:,iLat)    = OuterMagPAllR(:,iLR)
     TH(:,iLat)    = OuterMagTAllR(:,iLR)
     InvBH(:,iLat) = OuterMagInvBAllR(:,iLR)
     LatH(:,iLat)  = LatitudeAllR(:,iLR)
     JrH(:,iLat)   = OuterMagJr(:,iLR)
  enddo

  if (iConductanceModel == 5) then
     call old_aurora(RhoH,PH,TH, JrH, InvBH, LatH, OCFLBH, eFluxH, AveEH)
  else
     call solve_for_aurora(RhoH,PH,TH, JrH, InvBH, LatH, OCFLBH, eFluxH, AveEH)
  endif

  ! Move results back into main variables
  do iLat = 1, nLats/2
     ! iLR = iLat Reversed (from North pole to equator)
     iLR = nLats-iLat+1

     OuterMagRhoAllR(:,iLR) = RhoH(:,iLat)

     AveE(:,iLR)  = AveEH(:,iLat)
     eFlux(:,iLR) = eFluxH(:,iLat)
     if (maxval(InnerMagAveE) > 0.0 .and. iConductanceModel == 7) then

        AveE(:,iLR) = &
          (EFluxH(:,iLat) + InnerMagEFlux(:,iLR)) / ( &
          EFluxH(:,iLat)/AveEH(:,iLat) + &
          InnerMagEFlux(:,iLR)/InnerMagAveE(:,iLR)) 

        EFlux(:,iLR) = ( &
          EFluxH(:,iLat)/AveEH(:,iLat) + &
          InnerMagEFlux(:,iLR)/InnerMagAveE(:,iLR)) * AveE(:,iLR)

!        EFlux(:,iLR) = InnerMagEFlux(:,iLR)
!        AveE(:,iLR)  = InnerMagAveE(:,iLR) 
        where(AveE < 0.25) AveE = 0.25
        where(EFlux < 0.1) EFlux = 0.1
     endif
  enddo

  do iLon = 0, nLons+1
     ! Need to shift longitudes
     iLonTo   = iLon
     iLonFrom = mod(iLon + iProc*nLons, nLons*nProc)
     if (iLonFrom == 0) iLonFrom = nLons*nProc
     OCFLB(2,iLonTo) = OCFLBH(iLonFrom)
  enddo

  deallocate(rhoH,pH,TH,InvBH,LatH,OCFLBH)

end subroutine calc_aurora

!------------------------------------------------------------------------

subroutine solve_for_aurora(RhoH, PH, TH, JrH, InvBH, LatH, &
     OCFLBH, eFluxH, AveEH)

  use ModRIM
  use ModParamRIM
  use ModNumConst, only: cDegToRad, cPi
  use ModProcIE

  implicit none

  ! Variables that have an 'H' stuck on the end are only defined for a
  ! hemisphere
  real, dimension(0:nLonsAll+1,nLats/2) :: &
       rhoH, pH, TH, InvBH, LatH
  real, dimension(0:nLons+1,nLats/2), intent(in)  :: JrH
  real, dimension(0:nLons+1,nLats/2), intent(out) :: eFluxH, AveEH
  real, dimension(0:nLonsAll+1), intent(out) :: OCFLBH

  real, allocatable :: pNorm(:,:)

  real, dimension(0:nLons+1,nLats/2) :: PolarRain_eFlux, PolarRain_AveE
  real, dimension(0:nLons+1,nLats/2) :: Discrete_eFlux, Discrete_AveE, Discrete_K
  real, dimension(0:nLons+1,nLats/2) :: Diffuse_eFlux, Diffuse_AveE
  real, allocatable :: Width(:), smooth(:), Center(:)

  real :: smoothlat(nLats/2)

  integer :: iLon, iLat, nSmooth, iSubLon, l, iLonOff, iLonG, iLonM
  integer :: i, iCount
  logical :: IsDone, IsPeakFound
  real :: MaxP
  real :: Discrete_FacAE, Discrete_FacEF
  real :: Diffuse_FacAE, Diffuse_FacEF
  real :: LonOffset, Diffuse_EFlux_Max
  real :: Discrete_AveE_Max, Discrete_EFlux_Max

  allocate( &
       pNorm(0:nLonsAll+1,nLats/2), &
       Width(0:nLonsAll+1), &
       Smooth(0:nLonsAll+1), &
       Center(0:nLonsAll+1))

  iLonOff = iProc*nLons

  Discrete_FacAE = 0.4e23
  Discrete_FacEF = 2.0e23
  Diffuse_FacAE = 5.0e-11
  Diffuse_FacEF = 1.0e9
  Diffuse_EFlux_Max = 15.0
  Discrete_EFlux_Max = 50.0
  Discrete_AveE_Max  = 30.0

  LonOffset = 0.0 ! -3*cPi/12.0

  MinPressure = 5.0e-9
  OCFLBSmoothLon = 15.0*cDegToRad

  nSmooth = OCFLBSmoothLon/(Longitude(1,1) - Longitude(0,1))

  eFluxH = 0.0001
  AveEH  = 0.5
  OCFLBH = 1.0e32

  ! One of the problems with the MHD code is that the pressure can
  ! be miserably low.  So, let's set a minimum value for the maximum pressure,
  ! bringing the maximum up to this value, but keeping the shape.

  pNorm = pH

  if (maxval(pNorm) < MinPressure) &
       pNorm = pNorm/maxval(pNorm)*MinPressure

  ! First, find open closed field-line boundary

  Width = 0.0
  do iLon = 0, nLonsAll+1

     IsDone = .false.
     IsPeakFound = .false.
     MaxP = maxval(pNorm(iLon,:))

     iLat = 1

     do while (.not. IsDone)

        if (InvBH(iLon, iLat) > 0) then

           ! Set OCFLB to latitude of first open field-line
           if (OCFLBH(iLon) == 1.0e32) &
                OCFLBH(iLon) = abs(LatH(iLon,iLat))

           ! Find the peak location of the pressure - this may be the location
           ! of the inner edge of the plasma sheet.
           if (pNorm(iLon,iLat) == MaxP) IsPeakFound = .true.

           ! Determine the width of the oval.  We want it to be greater
           ! than some minimum width
           Width(iLon) = OCFLBH(iLon) - abs(LatH(iLon,iLat))

           if (IsPeakFound .and. Width(iLon) >= MinAuroralWidth) &
                IsDone = .true.

        else 

           ! if we encounter an open "pocket" in a closed region, then
           ! this will start the search over again.

           OCFLBH(iLon) = 1.0e32

        endif

        iLat = iLat + 1

        if (iLat == nLats/2) then
           OCFLBH(iLon) = MaxAuroralLat
           Width(iLon) = MinAuroralWidth
           IsDone = .true.
        endif

     enddo

     if (OCFLBH(iLon) > MaxAuroralLat) OCFLBH(iLon) = MaxAuroralLat
     if (width(iLon) > 12.0*cDegToRad) width(iLon) = 12.0*cDegToRad

     Center(iLon) = OCFLBH(iLon) - Width(iLon)

     if (Center(iLon)+Width(iLon) > MaxAuroralLat+MinAuroralWidth) &
          Width(iLon) = MaxAuroralLat + MinAuroralWidth - Center(iLon)

  enddo

  do iLon = 0, nLonsAll+1
     smooth(iLon) = 0.0
     do iSubLon = iLon-nSmooth, iLon+nSmooth
        smooth(iLon) = smooth(iLon) + OCFLBH(mod(iSubLon+nLonsAll,nLonsAll))
     enddo
  enddo
  OCFLBH = smooth/(2*nSmooth+1)

  do iLon = 0, nLonsAll+1
     smooth(iLon) = 0.0
     do iSubLon = iLon-nSmooth, iLon+nSmooth
        smooth(iLon) = smooth(iLon) + Center(mod(iSubLon+nLonsAll,nLonsAll))
     enddo
  enddo
  Center = smooth/(2*nSmooth+1)

  do iLon = 0, nLonsAll+1
     smooth(iLon) = 0.0
     do iSubLon = iLon-nSmooth, iLon+nSmooth
        smooth(iLon) = smooth(iLon) + Width(mod(iSubLon+nLonsAll,nLonsAll))
     enddo
  enddo
  Width = smooth/(2*nSmooth+1) / 2.0

  ! We want to put the Center of the diffuse aurora about 1/2 way between
  ! the open/closed field-line boundary and the inner edge of the 
  ! plasma sheet.  I don't know why.  It just seems like a good idea.
!  Center = OCFLBH - Width !/2

  ! ---------------------------
  ! Polar Rain

  PolarRain_AveE  = 0.5
  PolarRain_EFlux = 0.1

  do iLon = 0, nLons+1
     iLonG = iLon + iLonOff
     do iLat = 1, nLats/2
        if (abs(LatH(iLonG,iLat)) > OCFLBH(iLonG)) then
           PolarRain_AveE(iLon,iLat) = PolarRainAveE
           PolarRain_EFlux(iLon,iLat) = PolarRainEFlux
        endif
     enddo
  enddo

  ! ---------------------------
  ! Diffuse Aurora

  Diffuse_AveE = 0.0
  Diffuse_EFlux = 0.0

  do iLon = 0, nLons+1

     ! The exponential represents the radial location of the main aurora, 
     ! or approximately the inner edge of the plasma sheet.  The cos takes
     ! into account the loss of electrons as a function of MLT due to 
     ! pitch angle scattering.  The nLons+1-iLon (i.e., mirroring the 
     ! location of the maximum pressure), is due to the electrons wanting
     ! to drift one way and the ions wanting to drift westward.

     iLonG = iLon + iLonOff
     iLonM = nLonsAll+1 - iLonG

     MaxP = maxval(pNorm(iLonM,:))

     Diffuse_EFlux(iLon,:) = &
          Diffuse_EFlux_Max * tanh(MaxP * Diffuse_FacEF * cPi / 100.0) * &
          exp(-abs(center(iLonG)-abs(LatH(iLonG,:)))/Width(iLonG))*&
          (0.375*cos(longitude(iLon,1:nLats/2))+0.625)

     where(tH(iLonM,:) > 0) &
          Diffuse_AveE(iLon,:) = (tH(iLonM,:) * Diffuse_FacAE)**0.5

     ! The average energy can sometimes be quite concentrated near
     ! the open/closed field-line boundary, which is a problem, since
     ! the eflux is spread out over significant distances. (i.e., we have
     ! the situation in which there is massive amounts of low energy
     ! electrons precipitating...)

     l = maxloc(Diffuse_AveE(iLon,:),dim=1)

     ! Let's smooth it a little bit, but keep some of the original "edge"
     Diffuse_AveE(iLon,:) = &
          0.25 * Diffuse_AveE(iLon,:) + &
          0.75 * Diffuse_AveE(iLon, l) * &
          exp(-abs(center(iLonG)-abs(LatH(iLonG,:)))/Width(iLonG))

  enddo

!  do iLon = 0, nLonsAll+1
!     iLat = 1
!     do while (rhoH(iLon,iLat) == 0.0)
!        iLat = iLat + 1
!     enddo
!     rhoH(iLon,1:iLat-1) = rhoH(iLon,iLat)
!     tH(iLon,1:iLat-1) = tH(iLon,iLat)
!     pNorm(iLon,1:iLat-1) = pNorm(iLon,iLat)
!  enddo
!
!  do iLon = 0, nLonsAll+1
!     do iLat = 1, nLats/2
!        if (latH(iLon,iLat) > center(iLon)) then
!           rhoH(iLon,iLat) = rhoH(iLon,iLat)* &
!                exp(-(abs(latH(iLon,iLat))-center(iLon))/(Width(iLon)*2))
!        endif
!     enddo
!  enddo
!
!  do iLat = 1, nLats/2
!     do iLon = 0, nLonsAll+1
!        smooth(iLon) = 0.0
!        do iSubLon = iLon-nSmooth, iLon+nSmooth
!           smooth(iLon) = smooth(iLon) + &
!                rhoH(mod(iSubLon+nLonsAll,nLonsAll),iLat)
!        enddo
!     enddo
!     rhoH(:,iLat) = smooth/(2*nSmooth+1)
!  enddo
!
!  do iLat = 1, nLats/2
!     do iLon = 0, nLonsAll+1
!        smooth(iLon) = 0.0
!        do iSubLon = iLon-nSmooth, iLon+nSmooth
!           smooth(iLon) = smooth(iLon) + &
!                pNorm(mod(iSubLon+nLonsAll,nLonsAll),iLat)
!        enddo
!     enddo
!     pNorm(:,iLat) = smooth/(2*nSmooth+1)
!  enddo
!
!  do iLat = 1, nLats/2
!     do iLon = 0, nLonsAll+1
!        smooth(iLon) = 0.0
!        do iSubLon = iLon-nSmooth, iLon+nSmooth
!           smooth(iLon) = smooth(iLon) + &
!                tH(mod(iSubLon+nLonsAll,nLonsAll),iLat)
!        enddo
!     enddo
!     tH(:,iLat) = smooth/(2*nSmooth+1)
!  enddo

  ! ---------------------------
  ! Discrete Aurora

  Discrete_AveE = 0.0
  Discrete_EFlux = 0.0
  Discrete_K = 0.0

  do iLon = 0, nLons+1
     
     iLonG = iLon + iLonOff
     iLonM = nLonsAll+1 - iLonG

     do iLat = 1,nLats/2
        rhoh(iLonG,iLat) = rhoH(iLonG,iLat) * ( &
             (cos(longitude(iLon,iLat)+LonOffset)+1.0)/2.0*0.5 + 0.5 - &
             ((cos(longitude(iLon,iLat)+LonOffset+cPi/2)+1.0)/2.0)**3*0.5)

        if (abs(LatH(iLonG,iLat)) > OCFLBH(iLonG)) &
             rhoh(iLonG,iLat) = rhoH(iLonG,iLat) * &
             exp((OCFLBH(iLonG)-abs(LatH(iLonG,iLat)))/OCFLBH(iLonG)*3.0)

        if (rhoh(iLonG,iLat) > maxRho) rhoh(iLonG,iLat) = maxRho

        if (pNorm(iLonG,iLat) > 0 .and. rhoH(iLonG,iLat) > 0) &
             Discrete_K(iLon,iLat) = &
             (rhoH(iLonG,iLat)**1.5) / pNorm(iLonG,iLat)
!        if (JrH(iLon,iLat) > 7.5e-8) &
        if (JrH(iLon,iLat) > 2.5e-7) &
             Discrete_EFlux(iLon,iLat) = &
             (JrH(iLon,iLat)*1e6)*Discrete_K(iLon,iLat)
     enddo
  enddo

  Discrete_AveE = Discrete_EFlux*Discrete_FacAE
  Discrete_EFlux = (JrH*1e6)*Discrete_EFlux*Discrete_FacEF

  where(Discrete_AveE > Discrete_AveE_Max) Discrete_AveE = Discrete_AveE_Max
  where(Discrete_EFlux > Discrete_EFlux_Max) Discrete_EFlux = Discrete_EFlux_Max

  ! We don't want any steep latitudinal gradients in the Hall conductance,
  ! so let's smooth this over a little bit.  This has to be improved, though.

  do iLon = 0, nLons+1
     
     smoothlat = 0.0
     do iLat = 1,nLats/2
        iCount = 0
        do i = iLat-4,iLat+4
           if (i >= 1 .and. i <= nLats/2) then
              smoothlat(iLat) = &
                   smoothlat(iLat) + &
                   Discrete_AveE(iLon, i)
              iCount = iCount + 1
           endif
        enddo
        Discrete_AveE(iLon,iLat) = smoothlat(iLat)/iCount
     enddo

     smoothlat = 0.0
     do iLat = 1,nLats/2
        iCount = 0
        do i = iLat-4,iLat+4
           if (i >= 1 .and. i <= nLats/2) then
              smoothlat(iLat) = &
                   smoothlat(iLat) + &
                   Discrete_EFlux(iLon, i)
              iCount = iCount + 1
           endif
        enddo
        Discrete_EFlux(iLon,iLat) = smoothlat(iLat)/iCount
     enddo

  enddo

  where(Diffuse_AveE < 0.25) Diffuse_AveE = 0.25
  where(Discrete_AveE < 0.25) Discrete_AveE = 0.25

  where(Diffuse_EFlux < 0.1) Diffuse_EFlux = 0.1
  where(Discrete_EFlux < 0.1) Discrete_EFlux = 0.1

  if (iDebugLevel > 2) then
     write(*,*) "RIM===>diffuse  : ",&
          maxval(Diffuse_AveE), maxval(Diffuse_EFlux)
     write(*,*) "RIM===>discrete : ",&
          maxval(Discrete_AveE), maxval(Discrete_EFlux)
     write(*,*) "RIM===>polar    : ",&
          maxval(PolarRain_AveE), maxval(PolarRain_EFlux)
  endif

  if (iConductanceModel == 7) then
     ! We want the diffuse aurora from RCM, and not from MHD

     ! Let's weight the average energy by the number flux, which is ef/av
     AveEH = &
          (Diffuse_EFlux + Discrete_EFlux + PolarRain_EFlux) / ( &
          Diffuse_EFlux/Diffuse_AveE + &
          Discrete_EFlux/Discrete_AveE + &
          PolarRain_EFlux/PolarRain_AveE) 

     EFluxH = ( &
          Diffuse_EFlux/Diffuse_AveE + &
          Discrete_EFlux/Discrete_AveE + &
          PolarRain_EFlux/PolarRain_AveE) * AveEH

  else

     ! Let's weight the average energy by the number flux, which is ef/av
     AveEH = &
          (Discrete_EFlux + PolarRain_EFlux) / ( &
          Discrete_EFlux/Discrete_AveE + &
          PolarRain_EFlux/PolarRain_AveE) 

     EFluxH = ( &
          Discrete_EFlux/Discrete_AveE + &
          PolarRain_EFlux/PolarRain_AveE) * AveEH

  endif

  deallocate(pNorm, Width, Smooth, Center)

end subroutine solve_for_aurora


!------------------------------------------------------------------------

subroutine old_aurora(RhoH, PH, TH, JrH, InvBH, LatH, OCFLBH, eFluxH, AveEH)

  use ModRIM
  use ModParamRIM
  use ModNumConst, only: cDegToRad, cPi
  use ModProcIE
  use ModAuroraRIM

  implicit none

  ! Variables that have an 'H' stuck on the end are only defined for a
  ! hemisphere
  real, dimension(0:nLonsAll+1,nLats/2) :: &
       rhoH, pH, TH, InvBH, LatH
  real, dimension(0:nLons+1,nLats/2), intent(in)  :: JrH
  real, dimension(0:nLons+1,nLats/2), intent(out) :: eFluxH, AveEH
  real, dimension(0:nLonsAll+1), intent(out) :: OCFLBH

  real, allocatable :: Width(:), smooth(:), Center(:)

  real :: smoothlat(nLats/2), MaxP
  real :: y1, y2, x1, x2, distance, dlat, dmlt
  real :: hal_a0, hal_a1, hal_a2, hall, ped
  real :: ped_a0, ped_a1, ped_a2
  logical :: IsDone, IsPeakFound, IsPolarCap
  logical :: IsFirstTime = .true.
  integer :: iLon, iLat, iSubLon, nSmooth, iMlt, jLat, iLonOff, i 

  allocate( &
       Width(0:nLonsAll+1), &
       Smooth(0:nLonsAll+1), &
       Center(0:nLonsAll+1))

  iLonOff = iProc*nLons  
  OCFLBSmoothLon = 15.0*cDegToRad

  nSmooth = OCFLBSmoothLon/(Longitude(1,1) - Longitude(0,1))

  eFluxH = 0.0001
  AveEH  = 0.5
  OCFLBH = 1.0e32

  ! First, find open closed field-line boundary

  Width = 0.0
  do iLon = 0, nLonsAll+1

     IsDone = .false.
     IsPeakFound = .false.
     MaxP = maxval(pH(iLon,:))

     iLat = 1

     do while (.not. IsDone)

        if (InvBH(iLon, iLat) > 0) then

           ! Set OCFLB to latitude of first open field-line
           if (OCFLBH(iLon) == 1.0e32) &
                OCFLBH(iLon) = abs(LatH(iLon,iLat))

           ! Find the peak location of the pressure - this may be the location
           ! of the inner edge of the plasma sheet.
           if (pH(iLon,iLat) == MaxP) IsPeakFound = .true.

           ! Determine the width of the oval.  We want it to be greater
           ! than some minimum width
           Width(iLon) = OCFLBH(iLon) - abs(LatH(iLon,iLat))

           if (IsPeakFound .and. Width(iLon) >= MinAuroralWidth) &
                IsDone = .true.

        else 

           ! if we encounter an open "pocket" in a closed region, then
           ! this will start the search over again.

           OCFLBH(iLon) = 1.0e32

        endif

        iLat = iLat + 1

        if (iLat == nLats/2) then
           OCFLBH(iLon) = MaxAuroralLat
           Width(iLon) = MinAuroralWidth
           IsDone = .true.
        endif

     enddo

     if (OCFLBH(iLon) > MaxAuroralLat) OCFLBH(iLon) = MaxAuroralLat
     if (width(iLon) > 12.0*cDegToRad) width(iLon) = 12.0*cDegToRad

     Center(iLon) = OCFLBH(iLon) - Width(iLon)

     if (Center(iLon)+Width(iLon) > MaxAuroralLat+MinAuroralWidth) &
          Width(iLon) = MaxAuroralLat + MinAuroralWidth - Center(iLon)

  enddo

!  do iLon = 0, nLonsAll+1
!     smooth(iLon) = 0.0
!     do iSubLon = iLon-nSmooth, iLon+nSmooth
!        i = iSubLon
!        if (i < 1) i = i + nLonsAll
!        if (i > nLonsAll) i = i - nLonsAll
!        smooth(iLon) = smooth(iLon) + OCFLBH(i)
!     enddo
!  enddo
!  OCFLBH = smooth/(2*nSmooth+1)
!
!  do iLon = 0, nLonsAll+1
!     smooth(iLon) = 0.0
!     do iSubLon = iLon-nSmooth, iLon+nSmooth
!        i = iSubLon
!        if (i < 1) i = i + nLonsAll
!        if (i > nLonsAll) i = i - nLonsAll
!        smooth(iLon) = smooth(iLon) + Center(i)
!     enddo
!  enddo
!  Center = smooth/(2*nSmooth+1)
!
!  do iLon = 0, nLonsAll+1
!     smooth(iLon) = 0.0
!     do iSubLon = iLon-nSmooth, iLon+nSmooth
!        i = iSubLon
!        if (i < 1) i = i + nLonsAll
!        if (i > nLonsAll) i = i - nLonsAll
!        smooth(iLon) = smooth(iLon) + Width(i)
!     enddo
!  enddo
!  Width = smooth/(2*nSmooth+1) !/ 2.0

  Width = 5.0*cDegToRad
  ocflbh = 70.0*cDegToRad

  if (IsFirstTime) then
     call smooth_aurora
     IsFirstTime = .false.
  endif

  dlat = (cond_lats(1) - cond_lats(2))*cDegToRad
  dmlt = (cond_mlts(2) - cond_mlts(1))*cPi/12.0

  do iLon = 0, nLons+1
     do iLat = 1, nLats/2

        y1 = LatH(iLon,iLat)/dlat + 1.0
        if (y1 < 1) y1 = 1.0
        if (y1 > i_cond_nlats-1) then
           jlat = i_cond_nlats-1
           y1   = 1.0
        else
           jlat = y1
           y1   = 1.0 - (y1 - jlat)
        endif
        y2 = 1.0 - y1

        x1 = Longitude(iLon, iLat)/dmlt + 1.0
        if (x1 < 1) x1 = x1 + i_cond_nmlts
        if (x1 >= i_cond_nmlts+1) x1 = x1 - i_cond_nmlts
        imlt = x1
        x1   = 1.0 - (x1 - imlt)
        x2   = 1.0 - x1

        if (JrH(iLon,iLat) > 0) then

           hal_a0 = x1*y1*hal_a0_up(imlt  ,jlat  ) + &
                x2*y1*hal_a0_up(imlt+1,jlat  ) + &
                x1*y2*hal_a0_up(imlt  ,jlat+1) + &
                x2*y2*hal_a0_up(imlt+1,jlat+1)
           
           hal_a1 = x1*y1*hal_a1_up(imlt  ,jlat  ) + &
                x2*y1*hal_a1_up(imlt+1,jlat  ) + &
                x1*y2*hal_a1_up(imlt  ,jlat+1) + &
                x2*y2*hal_a1_up(imlt+1,jlat+1)

           hal_a2 = x1*y1*hal_a2_up(imlt  ,jlat  ) + &
                x2*y1*hal_a2_up(imlt+1,jlat  ) + &
                x1*y2*hal_a2_up(imlt  ,jlat+1) + &
                x2*y2*hal_a2_up(imlt+1,jlat+1)

           ped_a0 = x1*y1*ped_a0_up(imlt  ,jlat  ) + &
                x2*y1*ped_a0_up(imlt+1,jlat  ) + &
                x1*y2*ped_a0_up(imlt  ,jlat+1) + &
                x2*y2*ped_a0_up(imlt+1,jlat+1)

           ped_a1 = x1*y1*ped_a1_up(imlt  ,jlat  ) + &
                x2*y1*ped_a1_up(imlt+1,jlat  ) + &
                x1*y2*ped_a1_up(imlt  ,jlat+1) + &
                x2*y2*ped_a1_up(imlt+1,jlat+1)

           ped_a2 = x1*y1*ped_a2_up(imlt  ,jlat  ) + &
                x2*y1*ped_a2_up(imlt+1,jlat  ) + &
                x1*y2*ped_a2_up(imlt  ,jlat+1) + &
                x2*y2*ped_a2_up(imlt+1,jlat+1)
           
        else
           
           hal_a0 = x1*y1*hal_a0_do(imlt  ,jlat  ) + &
                x2*y1*hal_a0_do(imlt+1,jlat  ) + &
                x1*y2*hal_a0_do(imlt  ,jlat+1) + &
                x2*y2*hal_a0_do(imlt+1,jlat+1)

           hal_a1 = x1*y1*hal_a1_do(imlt  ,jlat  ) + &
                x2*y1*hal_a1_do(imlt+1,jlat  ) + &
                x1*y2*hal_a1_do(imlt  ,jlat+1) + &
                x2*y2*hal_a1_do(imlt+1,jlat+1)

           hal_a2 = x1*y1*hal_a2_do(imlt  ,jlat  ) + &
                x2*y1*hal_a2_do(imlt+1,jlat  ) + &
                x1*y2*hal_a2_do(imlt  ,jlat+1) + &
                x2*y2*hal_a2_do(imlt+1,jlat+1)

           ped_a0 = x1*y1*ped_a0_do(imlt  ,jlat  ) + &
                x2*y1*ped_a0_do(imlt+1,jlat  ) + &
                x1*y2*ped_a0_do(imlt  ,jlat+1) + &
                x2*y2*ped_a0_do(imlt+1,jlat+1)

           ped_a1 = x1*y1*ped_a1_do(imlt  ,jlat  ) + &
                x2*y1*ped_a1_do(imlt+1,jlat  ) + &
                x1*y2*ped_a1_do(imlt  ,jlat+1) + &
                x2*y2*ped_a1_do(imlt+1,jlat+1)

           ped_a2 = x1*y1*ped_a2_do(imlt  ,jlat  ) + &
                x2*y1*ped_a2_do(imlt+1,jlat  ) + &
                x1*y2*ped_a2_do(imlt  ,jlat+1) + &
                x2*y2*ped_a2_do(imlt+1,jlat+1)

        endif

        distance = abs(LatH(iLon,iLat) - OCFLBH(iLon+iLonOff))/3.0
   
        hal_a0 = hal_a0 * exp(-1.0*(distance/(Width(iLon+iLonOff)))**2)
        ped_a0 = ped_a0 * exp(-1.0*(distance/(Width(iLon+iLonOff)))**2)

        !
        ! A sort of correction on the fit
        !

        hal_a1 = hal_a0 + (hal_a1 - hal_a0)*  &
             exp(-1.0*(distance/Width(iLon+iLonOff))**2)
        ped_a1 = ped_a0 + (ped_a1 - ped_a0)*  &
             exp(-1.0*(distance/Width(iLon+iLonOff))**2)

        ! Multiply by sqrt(3) to compensate for the 3 times narrower oval
        hall=1.7*( &
             hal_a0-hal_a1*exp(-abs(JrH(iLon,iLat)*1.0e9)*hal_a2**2))
        ped =1.7*( &
             ped_a0-ped_a1*exp(-abs(JrH(iLon,iLat)*1.0e9)*ped_a2**2))

        if (hall > 1.0 .and. ped > 0.5) then
           AveEH(iLon,iLat) = ((hall/ped)/0.45)**(1.0/0.85)
           EFluxH(iLon,iLat) = (ped*(16.0+AveEH(iLon,iLat)**2)/&
                (40.0*AveEH(iLon,iLat)))**2

        endif

     enddo
  enddo

end subroutine old_aurora
