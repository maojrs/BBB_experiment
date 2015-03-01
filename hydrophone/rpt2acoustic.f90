! =====================================================
subroutine rpt2(ixy,imp,maxm,meqn,mwaves,maux,mbc,mx,ql,qr,aux1,aux2,aux3,asdq,bmasdq,bpasdq)
! =====================================================

      implicit double precision (a-h,o-z)
!
!     # Riemann solver in the transverse direction for the Euler equations.
!     # Split asdq (= A^* \Delta q, where * = + or -)
!     # into down-going flux difference bmasdq (= B^- A^* \Delta q)
!     #    and up-going flux difference bpasdq (= B^+ A^* \Delta q)
!
!     # Uses approximation to acoustic eqs to calculate downward and upward
!     # contributions with impedance and sound speed where there is an interface
!
      ! Declare left right states, fluctuation from normal solver (asdq)
      ! transverse fluctuations, and auxiliary variables
      ! See Clawpack documentation for more details.
      dimension     ql(meqn, 1-mbc:maxm+mbc)
      dimension     qr(meqn, 1-mbc:maxm+mbc)
      dimension   asdq(meqn, 1-mbc:maxm+mbc)
      dimension bmasdq(meqn, 1-mbc:maxm+mbc)
      dimension bpasdq(meqn, 1-mbc:maxm+mbc)
      dimension aux1(maux, 1-mbc:maxm+mbc)
      dimension aux2(maux, 1-mbc:maxm+mbc)
      dimension aux3(maux, 1-mbc:maxm+mbc)
!
      ! Load common block parameters (EOS parameters and densities)
      common /param/ gammagas, gammaplas, gammawat
      common /param/ pinfgas,pinfplas,pinfwat
      common /param/ omegas,omeplas,omewat
      common /param/ rhog,rhop,rhow
      
      
      dimension waveb(4,3),sb(3)
      parameter (maxm2 = 1800)  !# assumes at most 200x200 grid with mbc=2
!
      double precision u2v2(3,-6:maxm2+7), &
            u(3,-6:maxm2+7), v(3,-6:maxm2+7), &
            enth(3,-6:maxm2+7),a(3,-6:maxm2+7), &
            g1a2(3,-6:maxm2+7),euv(3,-6:maxm2+7)

      if (mbc > 7 .OR. maxm2 < maxm) then
         write(6,*) 'need to increase maxm2 or 7 in rpn'
         stop
      endif
!
      gamma1 = gammagas - 1.d0

      if (ixy.eq.1) then
          mu = 2
          mv = 3
        else
          mu = 3
          mv = 2
        endif
        

!     Calculate relevant quantities in the three transverse cells 3-up, 2-middle, 1 down 
      do 10 i = 2-mbc, mx+mbc
        ! Obtain current data from aux arrays aux1,aux2,aux3
        ! 3-up 2-middle 1-down
        
        ! Densities
        rho3 = aux3(4,i)
        rho2 = aux2(4,i)
        rho1 = aux1(4,i)
        
        ! Normal velocities
        u(3,i) = aux3(mu+3,i)/rho3
        u(2,i) = aux2(mu+3,i)/rho2
        u(1,i) = aux1(mu+3,i)/rho1

        ! Transverse velocities
        v(3,i) = aux3(mv+3,i)/rho3
        v(2,i) = aux2(mv+3,i)/rho2
        v(1,i) = aux1(mv+3,i)/rho1
        
        ! Internal energies
        ene3 = aux3(7,i) 
        ene2 = aux2(7,i) 
        ene1 = aux1(7,i) 
        
        ! Kinetc energies 
        enek3 = 0.5*(u(3,i)**2 + v(3,i)**2)/rho3
        enek2 = 0.5*(u(2,i)**2 + v(2,i)**2)/rho2
        enek1 = 0.5*(u(1,i)**2 + v(1,i)**2)/rho1

        ! Obtain parameters from aux array
        gamma3 = aux3(1,i)
        gamma2 = aux2(1,i)
        gamma1 = aux1(1,i)
        pinf3 = aux3(2,i)
        pinf2 = aux2(2,i)
        pinf1 = aux1(2,i)
        
        ! Calculate pressures
        p3 = (gamma3 - 1)*(ene3 - enek3) - gamma3*pinf3
        p2 = (gamma2 - 1)*(ene2 - enek2) - gamma2*pinf2
        p1 = (gamma1 - 1)*(ene1 - enek1) - gamma1*pinf1

        ! Calculate enthalpies
        enth(3,i) = (ene3 + p3)/rho3 
        enth(2,i) = (ene2 + p2)/rho2
        enth(1,i) = (ene1 + p1)/rho1

        ! Calculate u^2 + v^2 array
        u2v2(3,i) = u(3,i)**2 + v(3,i)**2
        u2v2(2,i) = u(2,i)**2 + v(2,i)**2
        u2v2(1,i) = u(1,i)**2 + v(1,i)**2

        ! Calculate speeds c
        a(3,i) = dsqrt(gamma3*(p3 + pinf3)/rho3)
        a(2,i) = dsqrt(gamma2*(p2 + pinf2)/rho2)
        a(1,i) = dsqrt(gamma1*(p1 + pinf1)/rho1)

        ! Calculate (gamma-1)/c^2 array
        g1a2(3,i) = (gamma3 -1.0)/a(3,i)**2	 
        g1a2(2,i) = (gamma2 -1.0)/a(2,i)**2
        g1a2(1,i) = (gamma1 -1.0)/a(1,i)**2

        ! Calculate H-u^2-v^2 array 
        euv(3,i) = enth(3,i) - u2v2(3,i) 
        euv(2,i) = enth(2,i) - u2v2(2,i)
        euv(1,i) = enth(1,i) - u2v2(1,i)

   10    continue
!
         ! Do transverse solver for upward direction using Bi,j+1 matrix
         ! And for downward direction Bi,j-1 matrix, no Roe averaging done
         do 20 i = 2-mbc, mx+mbc
            cond = 0
            ! Check if we are on an Horizonatal interface in transverse direction
            if ((gamma1 .eq. gamma2) .and. (gamma2 .eq. gamma3)) then
                ! Do normal transverse ROE solver
                cond = 0 ! 0= never uses traditional solver
            end if
            
            ! Do transverse solvers for interface case 
            ! Note velocity of "contact discontinuity" substracted (- v({3,1},i))
            if (cond .eq. 0) then     
                ! transmitted part of down-going wave:
                a1 = (a(2,i)*asdq(1,i) - asdq(mv,i)) / &
              (a(1,i) + a(2,i))
                ! transmitted part of up-going wave:
                a4 = (a(2,i)*asdq(1,i) + asdq(mv,i)) / &
              (a(2,i) + a(3,i))
              
                ! Use acoustics eqs to calculate acoustic waves;
                ! Contact discontinuity and shear wave neglected 
                ! (Consider we are using Lagrangian frame of ref, since grid is fixed)
                ! compute the flux differences bmasdq (Wave x /pm speed a)
                bmasdq(1,i) = -a(1,i) * a1 ! Acoustic version of aocustic wave
                bmasdq(mu,i) = 0.d0
                bmasdq(mv,i) = a(1,i) * a1 * a(1,i) ! Acoustic version of aocustic wave
                bmasdq(4,i) = 0.d0
      
                ! compute the flux differences bpasdq
                bpasdq(1,i) = a(3,i) * a4 ! Acoustic version of aocustic wave
                bpasdq(mu,i) = 0.d0
                bpasdq(mv,i) = a(3,i) * a4 * a(3,i) ! Acoustic version of aocustic wave
                bpasdq(4,i) = 0.d0
            end if
            
            ! Do usual no-interface transverse solver
            ! Without ROE avgs (there could be an interface in normal direction) 
            if (cond .eq. 1) then
                a3 = g1a2(2,i) * (euv(2,i)*asdq(1,i) &
                + u(2,i)*asdq(mu,i) + v(2,i)*asdq(mv,i) - asdq(4,i))
                a2 = asdq(mu,i) - u(2,i)*asdq(1,i)
                a4 = (asdq(mv,i) + (a(2,i)-v(2,i))*asdq(1,i) - a(2,i)*a3) &
                / (2.d0*a(2,i))
                a1 = asdq(1,i) - a3 - a4
        
                ! Calculate transverse waves
                waveb(1,1) = a1
                waveb(mu,1) = a1*u(2,i)
                waveb(mv,1) = a1*(v(2,i)-a(2,i))
                waveb(4,1) = a1*(enth(2,i) - v(2,i)*a(2,i))
                sb(1) = v(2,i) - a(2,i)
        
                waveb(1,2) = a3
                waveb(mu,2) = a3*u(2,i) + a2
                waveb(mv,2) = a3*v(2,i)
                waveb(4,2) = a3*0.5d0*u2v2(2,i) + a2*u(2,i)
                sb(2) = v(2,i)
        !
                waveb(1,3) = a4
                waveb(mu,3) = a4*u(2,i)
                waveb(mv,3) = a4*(v(2,i)+a(2,i))
                waveb(4,3) = a4*(enth(2,i)+v(2,i)*a(2,i))
                sb(3) = v(2,i) + a(2,i)
  !
  !           # compute the flux differences bmasdq and bpasdq
                do 50 m=1,meqn
                    bmasdq(m,i) = 0.d0
                    bpasdq(m,i) = 0.d0
                    do 50 mw=1,3
                        bmasdq(m,i) = bmasdq(m,i) &
                            + dmin1(sb(mw), 0.d0) * waveb(m,mw)
                        bpasdq(m,i) = bpasdq(m,i) &
                            + dmax1(sb(mw), 0.d0) * waveb(m,mw)
    50          continue
            end if 
!                 
   20       continue
!
      return
      end
