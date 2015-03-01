c ! NOTE: change number of waves to two to use HLL solver
c
c
c =========================================================
      subroutine rpn2(ixy,maxmx,meqn,mwaves,maux,mbc,mx,ql,qr,auxl,auxr,
     &           wave,s,amdq,apdq)
c =========================================================
c
c     # solve Riemann problems for the 2D Euler equations (normal solver) 
c     # using HLLC - Tamman-exact hybrid approximate Riemann solver
c
c     # On input, ql contains the state vector at the left edge of each cell
c     #           qr contains the state vector at the right edge of each cell
c     # On output, wave contains the waves, 
c     #            s the speeds, 
c     #            amdq the  left-going flux difference  A^- \Delta q
c     #            apdq the right-going flux difference  A^+ \Delta q
c
c     # Note that the i'th Riemann problem has left state qr(i-1,:)
c     #                                    and right state ql(i,:)
c     # From the basic clawpack routine step1, rp is called with ql = qr = q.
c
c
      ! Declare implicit, 4 left to right states (ql,qml,qmr,qr)
      ! wave speeds, waves, fluctuations and auxiliary variables.
      ! See Clawpack documentation for more details.
      implicit double precision (a-h,o-z)
      dimension   ql(meqn, 1-mbc:maxmx+mbc)
      dimension   qr(meqn, 1-mbc:maxmx+mbc)
      dimension   qm(meqn, 1-mbc:maxmx+mbc)
      dimension   qml(meqn, 1-mbc:maxmx+mbc)
      dimension   qmr(meqn, 1-mbc:maxmx+mbc)
      dimension    s(mwaves, 1-mbc:maxmx+mbc)
      dimension wave(meqn, mwaves, 1-mbc:maxmx+mbc)
      dimension amdq(meqn, 1-mbc:maxmx+mbc)
      dimension apdq(meqn, 1-mbc:maxmx+mbc)
      dimension auxl(maux,1-mbc:maxmx+mbc)
      dimension auxr(maux,1-mbc:maxmx+mbc)

c     ! local storage variables (to simplify calculations)
      parameter (max2 = 20002)  !# assumes at most 2000 grid points with mbc=2
      dimension u(-1:max2),v(-1:max2),u2v2(-1:max2),enth(-1:max2),
     &       al(-1:max2),ar(-1:max2),g1a2(-1:max2),euv(-1:max2),
     &       cROE(-1:max2)
     
      ! Load common block parameters (EOS parameters and densities)
      common /param/ gammagas, gammaplas, gammawat
      common /param/ pinfgas,pinfplas,pinfwat
      common /param/ omegas,omeplas,omewat
      common /param/ rhog,rhop,rhow

      !Not required for acoustics version of transverse solver
!       common /comroe/ u,v,u2v2,enth,al,ar,g1a2,euv
c
c     # Dimensional splitting
      if (ixy.eq.1) then
          mu = 2
          mv = 3
      else
          mu = 3
          mv = 2
      endif
      
c     # Compute some left and right quantities:
      do 20 i=2-mbc,mx+mbc
         xcell = -10.0 + (i-0.5d0)*.052
         if (ixy .eq. 2) then
            xcell = (i-0.5d0)*.05
         end if
         gammal = auxr(1,i-1)
         gammar = auxl(1,i)
         gamma1l = gammal - 1.0
         gamma1r = gammar - 1.0
         pinfl = auxr(2,i-1)
         pinfr = auxl(2,i)
         omel = auxr(3,i-1)
         omer = auxl(3,i)
         ! Densities
         rho_l = qr(1,i-1)
         rho_r = ql(1,i)
         ! Velocities
         ul = qr(mu,i-1)/rho_l
         ur = ql(mu,i)/rho_r
         vl = qr(mv,i-1)/rho_l
         vr = ql(mv,i)/rho_r
         ! Kinetic Energy
         ek_l = 0.5*rho_l*(ul**2 + vl**2)
         ek_r = 0.5*rho_r*(ur**2 + vr**2)
         ! Pressures (Use Tait EOS on water and/or plastic, SGEOS on air or SGEOS on both)
         pl = gamma1l*(qr(4,i-1) - ek_l) 
         pl = pl/(1.0 - omel*rho_l) - pinfl*gammal
         pr = gamma1r*(ql(4,i) - ek_r) 
         pr = pr/(1.0 - omer*rho_r) - pinfr*gammar

         ! Additional qunatites to pass to transverse solver (ROE averages)
         rhsqrtl = dsqrt(qr(1,i-1))
         rhsqrtr = dsqrt(ql(1,i))
         rhsq2 = rhsqrtl + rhsqrtr
         u(i) = (qr(mu,i-1)/rhsqrtl + ql(mu,i)/rhsqrtr) / rhsq2
         v(i) = (qr(mv,i-1)/rhsqrtl + ql(mv,i)/rhsqrtr) / rhsq2
         enth(i) = (((qr(4,i-1)+pl)/rhsqrtl
     &             + (ql(4,i)+pr)/rhsqrtr)) / rhsq2
         u2v2(i) = u(i)**2 + v(i)**2
         a2l = gamma1l*(enth(i) - .5d0*u2v2(i))
         a2r = gamma1r*(enth(i) - .5d0*u2v2(i))
         al(i) = dsqrt(a2l)
         ar(i) = dsqrt(a2r)
         g1a2(i) = 1.d0/(enth(i) - .5d0*u2v2(i))
         euv(i) = enth(i) - u2v2(i) 
         cROE(i) = (pl/rhsqrtl + pr/rhsqrtr) / rhsq2 + 
     &  0.5*((ur - ul)/rhsq2)**2
         gamma1ROE = (gamma1l*rhsqrtl + gamma1r*rhsqrtr) / rhsq2
         psiROE = (gamma1l*(qr(4,i-1) - ek_l)/rhsqrtl +
     & gamma1r*(ql(4,i) - ek_r)/rhsqrtr) / rhsq2
         cROE(i) = dsqrt(psiROE + gamma1ROE*cROE(i))
    

         ! Compute left and right sound sspeeds
         cl = dsqrt(gammal*(pl + pinfl)/rho_l)
         cr = dsqrt(gammar*(pr + pinfr)/rho_r)

         ! Compute the speed of left and right HLLC wave
         Sl = min(ul - cl,ur - cr) ! u(i) - a(i)
         Sr = max(ul + cl,ur + cr) ! u(i) + a(i),
         
         s(1,i) = 1.d0*Sl
         s(3,i) = 1.d0*Sr
         
         ! Compute HLLC middle speed state
         Sm = pr - pl + rho_r*ur*(ur - Sr) - rho_l*ul*(ul - Sl) 
         Sm = Sm/(rho_r*(ur - Sr) - rho_l*(ul - Sl))
         s(2,i) = 1.d0*Sm
        
         ! Calculate HLLC middle states
         do j=1,meqn
             qml(j,i) = rho_l*(Sl - ul)/(Sl - Sm)
             qmr(j,i) = rho_r*(Sr - ur)/(Sr - Sm)
         end do
         
         ! Add multiplicative terms to momentum ones
         qml(mu,i) = Sm*qml(mu,i)
         qmr(mu,i) = Sm*qmr(mu,i)
         qml(mv,i) = vl*qml(mv,i)
         qmr(mv,i) = vr*qmr(mv,i)
         ! Add second terms to energy one (see Toro pg. 325)
         qml(4,i) = qml(4,i)*(qr(4,i-1)/rho_l + 
     & (Sm - ul)*(Sm + pl/(rho_l*(Sl - ul))))
         qmr(4,i) = qmr(4,i)*(ql(4,i)/rho_r + 
     & (Sm - ur)*(Sm + pr/(rho_r*(Sr - ur))))
         ! Finished HLLC solver
         
         
         ! If in interface or any medium that is not air, do exact solver.
         if ((gammal .ne. 1.4) .or. (gammar .ne. 1.4)) then
            ! Do exact Tamman Riemann solver at interface and in water
            ! Newton's ,method to find zero of phi (given in phi_exact_tamman)
            pstar = 0.5*(pl + pr)
            pold = pstar + 10
            do while (abs(pstar - pold) > 0.0001)
              pold = pstar
              CALL phi_exact(gammal,gammar,pr,pl,rho_r,rho_l,ul,ur,
     & pinfl,pinfr,pstar,phi,phi_prime,rhos_l,rhos_r,ustar)
              pstar = pstar - phi/phi_prime
            end do
            
            ! Compute the speed of left and right wave (See delRazo or Ivings paper)
            betal = (pl + pinfl)*(gammal - 1.0)/(gammal + 1.0)
            betar = (pr + pinfr)*(gammar - 1.0)/(gammar + 1.0)
            alphal = 2.0/(rho_l*(gammal + 1.0))
            alphar = 2.0/(rho_r*(gammar + 1.0))
            Sl = ul - dsqrt((pstar + pinfl + betal)/alphal)/rho_l
            Sr = ur + dsqrt((pstar + pinfr + betar)/alphar)/rho_r
            
            ! Transform Riemann solver into a Lagrangian frame of reference
            s(1,i) = 1.d0*Sl - 1.0*ustar
            s(2,i) = 0.0*ustar
            s(3,i) = 1.d0*Sr - 1.0*ustar
            

            ! Calculate densities, momentums and energys in middle states
            qml(1,i) = rhos_l 
            qmr(1,i) = rhos_r 
            qml(mu,i) = qml(1,i)*ustar
            qmr(mu,i) = qmr(1,i)*ustar
            qml(mv,i) = qml(1,i)*vl !*rho_l*(Sl - ul)/(Sl - ustar)
            qmr(mv,i) = qmr(1,i)*vr!*rho_r*(Sr - ur)/(Sr - ustar)
            qml(4,i) = (pstar + gammal*pinfl)/(gammal - 1.0) + 
     & 0.5*(qml(mu,i)**2 + qml(mv,i)**2)/qml(1,i)
            qmr(4,i) = (pstar + gammar*pinfr)/(gammar - 1.0) + 
     & 0.5*(qmr(mu,i)**2 + qmr(mv,i)**2)/qmr(1,i)
         end if
         ! Finished exact solver

c        # Compute the 3 waves.
c        j index over q variables
         do j=1,meqn
             q_l = qr(j,i-1)
             q_r = ql(j,i)
             wave(j,1,i) = qml(j,i) - q_l
             wave(j,2,i) = qmr(j,i) - qml(j,i)
             wave(j,3,i) = q_r - qmr(j,i) 
         end do
         
   20    continue
 
c
      ! Calculate fluctuations
c     # amdq = SUM s*wave   over left-going waves
c     # apdq = SUM s*wave   over right-going waves
c
      do 100 m=1,meqn
         do 100 i=2-mbc, mx+mbc
            amdq(m,i) = 0.d0
            apdq(m,i) = 0.d0
            do 90 mw=1,mwaves
               if (s(mw,i) .lt. 0.d0) then
                   amdq(m,i) = amdq(m,i) + s(mw,i)*wave(m,mw,i)
                 else
                   apdq(m,i) = apdq(m,i) + s(mw,i)*wave(m,mw,i)
                 endif
   90          continue
  100       continue
      go to 900
c
c-----------------------------------------------------

c

c
  900 continue
      return
      end

