!
      module cons_module
!
! This software is part of the NCAR TIE-GCM.  Use is governed by the 
! Open Source Academic Research License Agreement contained in the file 
! tiegcmlicense.txt.
!
      use params_module,only: dlat,dz,nlon,nlonp1,nlonp4,nlat,nlatp1,
     |  dlev,nlev,nmlat,nmlon,nmlonp1,zmbot,zmtop,zibot,zitop,dlon,
     |  glon,glat,glon1,glat1,zpmid,zpint,gmlon,gmlat,zpmag,zpimag,
     |  dmlev,nlevp1,nmlevp1,nimlevp1,zpbot_dyn,zpibot_dyn,rp
      implicit none
!
! Define model constants. 
! Parameter constants are cons_module module data and are accessed 
!   in subroutines via use-association. 
! Derived constants are cons_module module data, and are calculated
!   in sub init_cons (contained in cons_module). 
!   Sub init_cons is called by sub init (init_mod.F).
! Parameter constants:
!
      integer,parameter :: ndays =366  ! maximum number of days in a year
      real(rp),parameter ::
     |  dzp  = dz,           ! alias for dz (also dlev)
     |  re   = 6.37122e8_rp,    ! earth radius (cm)                  C(51)
     |  re_dyn = 6.378165e8_rp, ! earth radius for apex
     |  re_inv = 1._rp/re,      ! inverse of earth radius            C(52)
     |  avo  = 6.023e23_rp,     ! avogadro number                    C(85)
     |  boltz = 1.38E-16_rp,    ! boltzman's constant                C(84)
     |  p0   = 5.0e-4_rp,       ! standard pressure                  C(81)
     |  gask = 8.314e7_rp,      ! gas constant                       C(57)
     |  grav_par = 3.986004415e20_rp, ! standard gravitational parameter (cm^3/sec^2)
     |  brn2d = 0.6_rp,         !
     |  tbound = 181.0_rp,      ! background tn at lower boundary (tiegcm)
     |  atm_amu = 28.9_rp,      ! mean mass of surface atmosphere    C(24)
     |  dtsmooth = 0.95_rp,     ! time smoothing constant            C(30)
     |  dtsmooth_div2 = 0.5_rp*(1._rp-dtsmooth), !                      C(31)
     |  tgrad = 6._rp,          ! TN gradient from old /RUNMDS/ (tiegcm)
     |  nob(nlat) = 4.e6_rp,    ! N(NO) LBC from old /RUNMDS/
     |  avto = 4.0e-12_rp,      ! from old /RUNMDS/ (not used)
     |  hor(nlat) = .25_rp,     ! horizontal variation of eddy diffusion and
                             !  eddy thermal conductivity. If unity, value
                             !  of KE at bottom is 5.e-6 (old /RUNMDS/)
     |  prndtl = 1._rp,         ! prandtl number
     |  evergs = 1.602e-12_rp,  ! 1 eV = 1.602e-12 ergs
     |  tsurplus=5.11_rp*evergs ! surplus heat per event (ergs)    C(45)
!
! Smoothing constant is dependent on timestep (see below), so cannot be a parameter.
! (in previous revisions, shapiro=3.e-2, with no timestep or resolution dependence)
!
        real(rp) :: shapiro      ! shapiro smoother constant
        real(rp) :: default_step ! default timestep at current resolution.
        real(rp) :: smooth_fac   ! smoothing factor (typically 3.e-3)
!
      integer :: nlonper=nlonp4 ! nlon + periodic points (alias for nlonp4)
!
! Many expressions require x/rmass, but its more efficient on some
! platforms to multiply rather than divide, so set rmassinv = 1./rmass 
! here, and use x*rmassinv in the code.
!
      real(rp),parameter ::
     |  rmass_o2  = 32._rp, rmass_o1 = 16._rp, rmass_he = 4._rp,
     |  rmass_n2 = 28., rmass_n4s = 14._rp, rmass_no = 30._rp,
     |  rmass_ar = 40._rp, rmass_op = 16., rmass_n2d = 14._rp,
     |  rmass_co2 = 44._rp
      real(rp),parameter ::
     |  rmassinv_o2  = 1._rp/rmass_o2,
     |  rmassinv_o1  = 1._rp/rmass_o1,
     |  rmassinv_he  = 1._rp/rmass_he,
     |  rmassinv_n2  = 1._rp/rmass_n2,
     |  rmassinv_n4s = 1._rp/rmass_n4s,
     |  rmassinv_no  = 1._rp/rmass_no,
     |  rmassinv_ar  = 1._rp/rmass_ar,
     |  rmassinv_op  = 1._rp/rmass_op,
     |  rmassinv_n2d = 1._rp/rmass_n2d
!
! Model derived constants (see sub init_cons in this module):
!
      real(rp) ::
     |  pi,             ! set with 4*atan(1)    C(110)
     |  sqrtpi,         ! sqrt(pi)
     |  rtd,            ! radians-to-degrees (180./pi)
     |  dtr,            ! degrees-to-radians (pi/180.)
     |  dphi,           ! delta lat (pi/nlat)   C(2)
     |  dphi_2div3,     ! 2./(3.*dphi)          C(12)
     |  dphi_1div12,    ! 1./(12.*dphi)         C(13)
     |  dphi2_5div2,    ! 5./(2.*dphi**2)
     |  dphi2_4div3,    ! 4./(3.*dphi**2)
     |  dphi2_1div12,   ! 1./(12.*dphi**2)
     |  dlamda,         ! delta lon (2pi/nlon)  C(1)
     |  dlamda_2div3,   ! 2./(3.*dlamda)        C(10)
     |  dlamda_1div12,  ! 1./(12.*dlamda)       C(11)
     |  dlamda2_5div2,  ! 5./(2.*dlamda**2)
     |  dlamda2_4div3,  ! 4./(3.*dlamda**2)
     |  dlamda2_1div12, ! 1./(12.*dlamda**2)
     |  dt,             ! time step (secs)      C(4)
     |  dtx2,           ! 2*dt                  C(6)
     |  dtx2inv,        ! 1./(2*dt)             C(7)
     |  freq_3m3,       ! frequency of 2-day wave (rad/sec)       C(21)
     |  freq_semidi,    ! frequency of semidiurnal tide (rad/sec) C(23)
     |  expz(nlev+1),   ! exp(-z) at midpoints
     |  expzmid,        ! exp(-.5*dz)                             C(86)
     |  expzmid_inv,    ! 1./expzmid                              C(87)
     |  t0(nlev+1),     ! set by sub lowbound (bndry_mod.F)
     |  racs(nlat),     ! 1./(re*cs(lat))
     |  cs(-1:nlat+2),  ! cos(phi)
     |  cs2_inv(nlat),  ! 1/cos(phi)**2
     |  sn(nlat),       ! sin(phi)
     |  tn(nlat),       ! tan(phi)
     |  cor(nlat),
     |  grav,           ! accel due to gravity (dependent on lower boundary)
     |  dzgrav,         ! grav/gask C(65)
     |  difk(nlev+1,ndays),   ! background eddy diffusion
     |  dift(nlev+1,ndays),   ! background thermal conductivity
     |  xmue(nlev+1,ndays),   ! eddy viscosity (?)
     |  zbound,         ! background low bound of Z (formerly ZBA in annual tide)
     |  dipmin          ! minimum mag dip angle
!
! Constants for dynamo and electric field calculations:
      real(rp),parameter :: h0 =9.0e6_rp, r0 =re+h0    ! use mean earth radius
!
! Save gdlat,gdlon(nmlonp1,nmlat) in degrees from apex for sub define_mag (mpi.F)
!     real(rp),dimension(nmlonp1,nmlat) :: gdlatdeg,gdlondeg

      real(rp),parameter :: hs=1.3e7_rp
      real(rp) ::
     |  dlatg, dlong, dlatm, dlonm,dmagphrlon,
     |  ylatm(nmlat),    ! magnetic latitudes (radians)
     |  ylonm(nmlonp1),  ! magnetic longitudes (radians)
     |  rcos0s(nmlat),   ! cos(theta0)/cos(thetas)
     |  dt0dts(nmlat),   ! d(theta0)/d(thetas)
     |  dt1dts(nmlat),   ! dt0dts/abs(sinim) (non-zero at equator)
     |  table(91,2)

!
! Geographic grid in radians:
      real(rp) ::
     |  ylatg(0:nlatp1), ! geographic latitudes (radians)
     |  ylong(nlonp1)    ! geographic longitudes (radians)
!
! Critical colatitude limits (15,30 deg) for use of Heelis potential in dynamo:
! This is not a parameter because it may be changed by sub colath (colath.F).
      real(rp) :: crit(2) = (/0.261799387_rp, 0.523598775_rp/)
!
! If check_exp is set true, certain routines will use expo() (util.F)
! instead of exp(). expo checks for out of range arguments to the
! exponential, substituting large or small results if the argument
! is out of range. This avoids NaNS fpe's, but degrades performance.
! It will also produce slightly different results.
!
#ifdef DEBUG
      logical,parameter :: check_exp = .true.
#else
      logical,parameter :: check_exp = .false.
#endif
!
! Special pi for mag field calculations. If pi=4.*atan(1.) and code is
! linked with -lmass lib, then the last 2 digits (16th and 17th) of pi
! are different (56 instead of 12), resulting in theta0(j=49)==0., which 
! is wrong (should be .1110e-15).
!
      real(rp),parameter ::
     |  pi_dyn=3.14159265358979312_rp

      integer,parameter :: difhor=1
!
! smoothing factors for ring filter
      integer :: nlat_filter
      integer,dimension(:),allocatable :: chunk_array
!
      contains
!-----------------------------------------------------------------------
      subroutine init_cons
      use input_module,only: step,eddy_dif
      use params_module,only: tgcm_version
!
! Set derived constants (this is called from sub init in init_module)
!
! Local:
      real(rp) :: z,expdz,phi
      real(rp) :: omega = 7.292E-5_rp, pi = 4.0_rp*ATAN(1.0_rp)
      integer :: m,k,j,js
      integer :: calday(ndays)         ! calenday day in a year
      real(rp) :: coeff(9)
      real(rp) :: theta(ndays)
!
! Begin calculation of eddy diffusivity:
      if (eddy_dif > 0) then ! use DOY-dependent eddy diffusion
!
! The 9 coefficient of the semiannual eddy diffusivity parameterization:
        coeff(:)=(/4.06e-06_rp, -8.77e-07_rp, -2.28e-06_rp, 1.77e-06_rp,
     |    2.15e-06_rp, -3.05e-07_rp, -2.66e-07_rp,  4.08e-07_rp,
     |    1.59e-07_rp/)
!
! set up calendar days
        do m=1,ndays
           calday(m)=m
        enddo
!
! set up the theta array
        do m=1,ndays
           theta(m)=2._rp*pi*(calday(m)-1.)/(ndays-1.)
        enddo
!      
! calculate difk, dift, and xmue at first model level(bottom) in s^-1 for all
! the days in a year
!
        do m=1,ndays
           difk(1,m) = coeff(1) 
     |             + coeff(2)*sin(theta(m))+coeff(3)*cos(theta(m))
     |             + coeff(4)*sin(2.0_rp*theta(m))
     |             + coeff(5)*cos(2.0_rp*theta(m))
     |             + coeff(6)*sin(3.0_rp*theta(m))
     |             + coeff(7)*cos(3.0_rp*theta(m))
     |             + coeff(8)*sin(4.0_rp*theta(m))
     |             + coeff(9)*cos(4.0_rp*theta(m))
           dift(1,m) = difk(1,m)/prndtl
           xmue(1,m) = difk(1,m)
        enddo
!
!  calculate the rest of the levels
!
        expdz = exp(-dlev)
        do m=1,ndays
           do k=2,nlev+1
              difk(k,m) = difk(k-1,m)*expdz
              dift(k,m) = dift(k-1,m)*expdz
              if (k == nlev+1) then
                 xmue(k,m) = difk(k-1,m)
              else
                 xmue(k,m) = difk(k,m)
              endif
           enddo
        enddo
!
! Use constants if eddy_dif <= 0:
!
      else ! eddy_dif is off
        expz(:) = 0.0_rp ! init
        z = zibot+.5*dlev
        expz(1) = exp(-z)
        expdz = exp(-dlev)
        difk(1,:) = 5.0e-6_rp
        dift(1,:) = 5.0e-6_rp/prndtl
        xmue(1,:) = 5.0e-6_rp
        do k=2,nlev
          expz(k) = expz(k-1)*expdz
          difk(k,:) = difk(k-1,:)*expdz
          dift(k,:) = dift(k-1,:)*expdz
          xmue(k,:) = difk(k,:)
        enddo
        difk(nlev+1,:) = difk(nlev,:)*expdz
        dift(nlev+1,:) = dift(nlev,:)*expdz
        xmue(nlev+1,:) = difk(nlev,:)
      endif  ! eddy_dif on or off
!
      if (eddy_dif > 0) then
        write(6,"('init_cons: eddy_dif=',i3)") eddy_dif
        write(6,"('min,max: difk=',2e12.4,' dift=',2e12.4,' xmue=',
     |    2e12.4)") minval(difk),maxval(difk),minval(dift),maxval(dift),
     |              minval(xmue),maxval(xmue)
        write(6,"('difk(:,1)=',/,(6e12.4))") difk(:,1)
        write(6,"('dift(:,1)=',/,(6e12.4))") dift(:,1)
        write(6,"('xmue(:,1)=',/,(6e12.4))") xmue(:,1)
      endif
!
! end calculation of eddy diffusivity
!
      pi = 4.0_rp*atan(1.0_rp)                ! C(110)
      sqrtpi = sqrt(pi)               ! sqrt(pi)
      rtd = 180.0_rp/pi                   ! radians to degrees
      dtr = pi/180.0_rp                   ! degrees to radians
      dphi = pi/nlat           ! C(2)
      dphi_2div3 = 2.0_rp/(3.0_rp*dphi)       ! C(12)
      dphi_1div12 = 1.0_rp/(12.0_rp*dphi)     ! C(13)
      dphi2_5div2 = 5.0_rp/(2.0_rp*dphi**2)
      dphi2_4div3 = 4.0_rp/(3.0_rp*dphi**2)
      dphi2_1div12 = 1.0_rp/(12.0_rp*dphi**2)
      dlamda = 2.0_rp*pi/nlon      ! C(1)
      dlamda_2div3 = 2.0_rp/(3.0_rp*dlamda)   ! C(10)
      dlamda_1div12 = 1.0_rp/(12.0_rp*dlamda) ! C(11)
      dlamda2_5div2 = 5.0_rp/(2.0_rp*dlamda**2)   ! C(10)
      dlamda2_4div3 = 4.0_rp/(3.0_rp*dlamda**2)   ! C(10)
      dlamda2_1div12 = 1.0_rp/(12.0_rp*dlamda**2) ! C(11)
      zbound = 136.291_rp/sqrt(2.)*1.e5_rp  ! background lower boundary of Z (cm)
      dipmin = sin(dlat*2._rp*dtr)
!
! expz(kmax) is exp(-zp) at midpoints:
! expz (will replace EXPS) (expz(nlev+1) not used).
!
      expz(:) = 0.0_rp ! init
!
! bottom midpoint z = zibot + 1/2 deltaz (deltaz==dz==0.5 or 0.25)
! (zibot and dz are in params.h)
      z = zibot+.5_rp*dlev
      expz(1) = exp(-z)
      do k=2,nlev
        expz(k) = expz(k-1)*expdz
      enddo
      expzmid = exp(-.5_rp*dlev)
      expzmid_inv = 1.0_rp/expzmid
      js=-(nlat/2)
      do j=1,nlat
        phi=(j+js-.5_rp)*dphi
        cs(j)=cos(phi)
        sn(j)=sin(phi)
        tn(j)=tan(phi)
        cor(j)=2.0_rp*omega*sn(j)
        racs(j) = 1.0_rp/(re*cs(j))
        cs2_inv(j) = 1.0_rp/cs(j)**2
      enddo
!
! cs at 0, -1, nlat+1, and nlat+2 replace the old cssp and csnp:
      cs(-1) = -cs(2)
      cs(0)  = -cs(1)
      cs(nlat+1) = -cs(nlat)
      cs(nlat+2) = -cs(nlat-1)
      dt = float(step)                   ! was C(4)
      dtx2 = 2.0_rp*dt                       ! was C(6)
      dtx2inv = 1.0_rp/dtx2                  ! was C(7)
      freq_3m3 = 2.0_rp*pi/(49.7789_rp*60._rp*60._rp) ! was C(21)
      freq_semidi = 4.0_rp*pi/(24._rp*60._rp*60._rp)  ! was C(23)
!
! Set gravity according to lower boundary:
      grav = 870.0_rp ! (is 945. in time-gcm)
      dzgrav = grav/gask   ! C(65)
!
! Adjust smoothing constant as function of timestep:
! default_step: default step for shapiro=dt/def*fac.
!
      if (nlat==36 .and. nlon==72) then
        default_step = 60.0_rp
        nlat_filter = 5
        allocate(chunk_array(nlat_filter))
        chunk_array = (/3,9,18,36,36/)
      elseif (nlat==72 .and. nlon==144) then
        default_step = 30.0_rp
        nlat_filter = 10
        allocate(chunk_array(nlat_filter))
        chunk_array = (/3,3,9,9,18,18,36,36,72,72/)
      elseif (nlat==144 .and. nlon==288) then
        default_step = 10.0_rp
        nlat_filter = 21 !15
        allocate(chunk_array(nlat_filter))
        chunk_array = (/3,3,3,9,9,9,18,18,18,
     |    36,36,36,72,72,72,72,144,144,144,144,144/)
!        chunk_array = (/9,18,18,
!    |     36,36,36,
!    |     72,72,72,
!    |     144,144,144,144,144,144/)
      elseif (nlat==288 .and. nlon==576) then
        default_step = 5.0_rp
!        nlat_filter = 40
!        allocate(chunk_array(nlat_filter))
!        chunk_array = (/3,3,3,3,3,9,9,9,9,9,
!     |    18,18,18,18,18,18,36,36,36,36,36,36,72,72,72,72,72,72,
!     |    144,144,144,144,144,144,288,288,288,288,288,288/)
        nlat_filter = 34
        allocate(chunk_array(nlat_filter))
        chunk_array = (/3,3,3,9,9,9,
     |    18,18,18,36,36,36,36,36,
     |    72,72,72,72,72,72,72,72,
     |    144,144,144,144,144,144,288,288,288,288,288,288/)
      else
        call shutdown('Unknown combination of lat x lon')
      endif
      write(*,*) "CHUNK_ARRAY: ",chunk_array
!
! shapiro = dt/def*smooth_fac
      smooth_fac = 3.e-3_rp
      shapiro = dt/default_step * smooth_fac
!
! Report to stdout:
!     write(6,"(/,'Model name    = ',a)") tgcm_name
      write(6,"(  'Model version = ',a)") tgcm_version
      write(6,"(/,'Set constants:')")
      write(6,"('  nlat=',i3,' nlon=',i3,' nlev=',i3)") nlat,nlon,nlev
      write(6,"('  dz= ',f5.2)") dz
      write(6,"('  dlat=',f6.2,' dlon=',f6.2)") dlat,dlon
      write(6,"('  zbound (cm) = ',e14.6)") zbound
      write(6,"('  zmbot, zmtop = ',2f8.3,
     |  ' (bottom,top midpoint levels)')") zmbot,zmtop
      write(6,"('  zibot, zitop = ',2f8.3,
     |  ' (bottom,top interface levels)')") zibot,zitop
      write(6,"('  dt = ',f8.2,' secs')") dt
      write(6,"('  grav = ',f10.2)") grav
      write(6,"('  freq_3m3 = ',e12.4,'  freq_semidi=',e12.4)")
     |  freq_3m3,freq_semidi
      write(6,"('  dipmin = ',f8.3)") dipmin
      write(6,"('  check_exp = ',l1)") check_exp
      write(6,"('  step=',i4,' smooth_fac=',es9.2,' shapiro=',es9.2)")
     |  step,smooth_fac,shapiro
!
      end subroutine init_cons
!-----------------------------------------------------------------------
      subroutine consdyn
      use input_module,only: dynamo
!
! Set derived constants used in dynamo.
!
! Local:
      integer :: k,j,i,n
      real(rp),parameter :: e=1.e-6_rp, r1=1.06e7_rp, alfa=1.668_rp
      real(rp) ::
     |  tanth0(nmlat),
     |  tanths(nmlat),
     |  theta0(nmlat),
     |  hamh0(nmlat)
      real(rp) :: dtheta,table2(91,3:5),tanths2
!
! Must define pi, rtd, dtr, because consdyn is called before init_cons:
      pi = 4.0_rp*atan(1.0_rp)                ! C(110)
      rtd = 180.0_rp/pi                   ! radians to degrees
      dtr = pi/180.0_rp                   ! degrees to radians
!
! Set grid deltas:
      dlatg = pi/float(nlat)
      dlong = 2.0_rp*pi/float(nlon)
      dlatm = pi_dyn/(nmlat-1.0_rp) ! note use of pi_dyn
      dlonm = 2.0_rp*pi_dyn/float(nmlon)
!
! Set geographic latitude array ylatg:
      do j=1,nlat
        ylatg(j) = -0.5_rp*(pi-dlatg)+float(j-1)*dlatg
      enddo ! j=1,nlat
      ylatg(0) = -pi/2.0_rp+e
      ylatg(nlatp1) = pi/2.0_rp-e
!
! Set geographic longitude array ylong:
      do i=1,nlonp1
        ylong(i) = -pi+float(i-1)*dlong
      enddo ! i=1,nmlonp1
!
! Set magnetic latitudes ylatm and magnetic longitudes ylonm:
!
! ylatm is equally spaced in theta0, but holds corresponding value
!   of thetas.
      do j=1,nmlat
        theta0(j) = -pi_dyn/2.0_rp+float(j-1)*dlatm ! note use of pi_dyn
      enddo ! j=1,nmlat
      do j=2,nmlat-1
        tanth0(j) = abs(tan(theta0(j)))
        hamh0(j) = r1*tanth0(j)+r0*tanth0(j)**(2.0_rp+2.0_rp*alfa)/
     |    (1.0_rp+tanth0(j)**2)**alfa
        tanths(j) = sqrt(hamh0(j)/r0)
        ylatm(j) = sign(atan(tanths(j)),theta0(j))
        rcos0s(j) = sqrt((1.0_rp+tanths(j)**2)/(1.0_rp+tanth0(j)**2))
!
! If dynamo==0 -> dynamo is not calculated
! If dynamo==1 -> dynamo is calculated
!
        if (dynamo <= 0) then ! no dynamo
          dt1dts(j) = 0.0_rp
          dt0dts(j) = (2.0_rp*r0*tanths(j)*(1.0_rp+tanths(j)**2))/
     |      (r1*(1.0_rp+tanth0(j)**2)+
     |       2.0_rp*r0*tanth0(j)**(2.0_rp*alfa+1.)*
     |      (1.0_rp+alfa+tanth0(j)**2)/(1.0_rp+tanth0(j)**2)**alfa)
        else                  ! with dynamo
          tanths2  = tanths(j)**2
          dt1dts(j) =
     |      (r0*sqrt(1.0_rp+4.0_rp*tanths2)*(1.+tanths2))/
     |      (r1*(1.0_rp+tanth0(j)**2)+2.0_rp*
     |       r0*tanth0(j)**(2.0_rp*alfa+1.)*
     |      (1.0_rp+alfa+tanth0(j)**2)/(1.0_rp+tanth0(j)**2)**alfa)
          dt0dts(j) = dt1dts(j)*2.0_rp*tanths(j)/
     |      sqrt(1.0_rp+4.0_rp*tanths2)
        endif

!       write(6,"('consdyn: j=',i3,' tanth0=',e12.4,' hamh0=',e12.4,
!    |    ' tanths=',e12.4,' ylatm=',e12.4,' rcos0s=',e12.4,' dt0dts=',
!    |    e12.4,' dt1dts=',e12.4)") j,tanth0(j),hamh0(j),tanths(j),
!    |    ylatm(j),rcos0s(j),dt0dts(j),dt1dts(j)

      enddo ! j=2,nmlat-1
!
! Magnetic poles:
      ylatm(1) = theta0(1)
      ylatm(nmlat) = theta0(nmlat)
      rcos0s(1) = 1.0_rp
      rcos0s(nmlat) = 1.0_rp
      dt0dts(1) = 1.0_rp
      dt0dts(nmlat) = 1.0_rp
!
! Magnetic longitudes:
      do i=1,nmlonp1
        ylonm(i) = -pi+float(i-1)*dlonm
      enddo ! i=1,nmlonp1
      dtheta = pi/(2.0_rp*90.0_rp)
!
      table(1,1) = 0.0_rp
      table(1,2) = 0.0_rp
      do i=2,91
        table(i,1) = table(i-1,1)+dtheta
      enddo
      do i=2,90
        table2(i,4) = tan(table(i,1))
        table(i,2) = table(i,1)
      enddo ! i=2,90
      table(91,2) = table(91,1)
!     table(91,2) = pi/2.
      do n=1,7
        do i=2,90
          table2(i,3) = table(i,2)
          table(i,2) = tan(table2(i,3))
          table2(i,5) = sqrt(r1/r0*table(i,2)+
     |       table(i,2)**(2.0_rp*(1.+alfa))
     |      /(1.0_rp+table(i,2)**2)**alfa)
          table(i,2) = table2(i,3)-(table2(i,5)-table2(i,4))*2.0_rp*
     |      table2(i,5)/(r1/r0*(1.0_rp+
     |      table(i,2)**2)+2.0_rp*table(i,2)**
     |      (2.0_rp*alfa+1.0_rp)*(1.0_rp+alfa+table(i,2)**2)/
     |      (1.0_rp+table(i,2)**2)**
     |      alfa)
        enddo ! i=2,90
      enddo ! n=1,7
!
! Define mag grid in degrees, and mag levels:
      gmlat(:) = ylatm(:)*rtd
      gmlon(:) = ylonm(:)*rtd
!
! zpmag,zpimag = -8.5 -> +7.0 (k=1,nmlevp1) (mainly for history fields)
      do k=1,nmlevp1
        zpmag(k)  = zpbot_dyn +(k-1)*dmlev
      enddo
      do k=1,nimlevp1
        zpimag(k) = zpibot_dyn+(k-1)*dmlev
      enddo
!
!     write(6,"(/,'consdyn: ylatg =',/,(6e12.4))") ylatg
!     write(6,"(  'consdyn: ylong =',/,(6e12.4))") ylong
!     write(6,"(  'consdyn: ylatm =',/,(6e12.4))") ylatm
!     write(6,"(  'consdyn: ylonm =',/,(6e12.4))") ylonm

!     write(6,"(  'consdyn: rcos0s=',/,(6e12.4))") rcos0s
!     write(6,"(  'consdyn: dt0dts=',/,(6e12.4))") dt0dts
!     write(6,"(  'consdyn: table=',/,(6e12.4))") table
!     write(6,"(  'consdyn: table2=',/,(6e12.4))") table2
!
!     write(6,"(  'consdyn: nmlevp1=',i4,' zpmag=',/,(8f10.3))")
!    |  nmlevp1,zpmag
!     write(6,"(  'consdyn: nimlevp1=',i4,' zpimag=',/,(8f10.3))")
!    |  nimlevp1,zpimag
!
      end subroutine consdyn
!-----------------------------------------------------------------------
      subroutine set_geogrid
      integer :: i,j,k
!
! Define geographic grid:
      do i=1,nlon
        glon(i) = glon1+(i-1)*dlon
      enddo
      do j=1,nlat
        glat(j) = glat1+(j-1)*dlat
      enddo
      do k=1,nlevp1
        zpmid(k) = zmbot+(k-1)*dlev  ! midpoint levels
        zpint(k) = zibot+(k-1)*dlev  ! interface levels
      enddo
      end subroutine set_geogrid
!-----------------------------------------------------------------------
      end module cons_module
