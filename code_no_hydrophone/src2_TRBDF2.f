c
c      =======================================================
      subroutine src2(meqn,mbc,mx,my,xlower,ylower,
     &                 dx,dy,q,maux,aux,t,dt)
c      =======================================================
c
      implicit double precision (a-h,o-z)
      dimension    q(meqn,1-mbc:mx+mbc,1-mbc:my+mbc)
      dimension  aux(maux,1-mbc:mx+mbc,1-mbc:my+mbc)
      dimension  yt(1:4), ys(1:4), yout(1:4)
c
c     # dummy subroutine for use when equation has no source term.
c     # If method(5)=0 then this routine is never called, but its
c     # existence may be required by some compilers.
      do i=1-mbc,mx+mbc 
        xcell = xlower + (i-0.5d0)*dx 
        do j=1-mbc,my+mbc 
            r = ylower + (j-0.5d0)*dy + 5.d0*dy ! Artificil extra to avoid almost singular stiif source terms
            ! Equation of state variables             
            gamma = aux(1,i,j)
            pinf = aux(2,i,j)
            omega = aux(3,i,j)
            
            yt(1) = q(1,i,j)
            yt(2) = q(2,i,j)
            yt(3) = q(3,i,j)
            yt(4) = q(4,i,j)
            
            ! DO TR-BDF2 (See mini-research notebook)
            ! Trapezoidal part (just as before)
            uz = yt(2)/yt(1)
            ur = yt(3)/yt(1)
            ekt = 0.5*yt(1)*(uz**2 + ur**2)
            pt = (gamma - 1.0)*(yt(4) - ekt) - gamma*pinf
            del = dt*ur/(4.0*r)
            ys(1) = yt(1)*(1.0 - del)/(1.0 + del)
            ys(2) = yt(2)*(1.0 - del)/(1.0 + del)
            ys(3) = ys(1)*ur
            eks = 0.5*(ys(2)**2 + ys(3)**2)/ys(1)
            ys(4) = yt(4) - del*(yt(4) + pt - (gamma - 1.0)*eks - 
     & gamma*pinf)
            ys(4) = ys(4)/(1.0 + gamma*del)
            ! BDF part
            del = ur*dt/(3.0*r)
            yout(1) = (4.0*ys(1)/3.0 - yt(1)/3.0)/(1.0 + del)
            yout(2) = (4.0*ys(2)/3.0 - yt(2)/3.0)/(1.0 + del)
            yout(3) = yout(1)*ur
            ekout = 0.5*(yout(2)**2 + yout(3)**2)/yout(1)
            yout(4) = (4.0*ys(4)/3.0 - yt(4)/3.0 - del*((1.0 - gamma)*
     & ekout - gamma*pinf))
            yout(4) = yout(4)/(1.0 + gamma*del)
            
!             ! Do Trapezoidal method only (works the best so far)(see research notebook)
!             uz = yt(2)/yt(1)
!             ur = yt(3)/yt(1)
!             ekt = 0.5*yt(1)*(uz**2 + ur**2)
!             pt = (gamma - 1.0)*(yt(4) - ekt) - gamma*pinf
!             del = dt*ur/(2.0*r)
!             yout(1) = yt(1)*(1.0 - del)/(1.0 + del)
!             yout(2) = yt(2)*(1.0 - del)/(1.0 + del)
!             yout(3) = yout(1)*ur
!             yout(4) = yt(4) - del*(yt(4) + pt - (gamma - 1.0)*ekt - 
!      & gamma*pinf)
!             yout(4) = yout(4)/(1.0 + gamma*del)
      
            
!             ! Do BDF method (see research notebook) Only first order accurate
! !             r= abs(r)
!             uz = yt(2)/yt(1)
!             ur = yt(3)/yt(1)
!             yout(1) = yt(1)/(1 + dt*ur/r)
!             yout(2) = yt(2)/(1 + dt*ur/r)
!             yout(3) = yout(1)*ur
!             
!             uz_out = yout(2)/yout(1)
!             ur_out = yout(3)/yout(1)
!             ek_out = -0.5d0*yout(1)*(ur_out**2 + uz_out**2)
!             yout(4) = yt(4) - (dt/r)*((gamma - 1.0)*ek_out - gamma*pinf)
!             yout(4) = yout(4)/(1 - dt*gamma*ur_out/r)
            
            
!           ! Not good for stiff problems
!           ! Do runge kutta fourth order 
!           CALL rk4(yt,yout,rcell,t,dt,gamma,pinf) 
            q(1,i,j) = yout(1)
            q(2,i,j) = yout(2)
            q(3,i,j) = yout(3)
            q(4,i,j) = yout(4)
        end do
      end do
      
      return
      end

      ! RK4 subroutine, requires a function FUNC that returns a vector
c      =======================================================
      subroutine rk4(yt,yout,r,t,dt,gamma,pinf)
      implicit double precision (a-h,o-z)
      dimension yt(1:4), yout(1:4)
      double precision, dimension(4) ::  k1,k2,k3,k4
      
      ! Returns k1,k2,k3 and k4 as k1 = f(y(t),t)...etc
      CALL RKFUNC(yt,t,r,k1,gamma,pinf)
      CALL RKFUNC(yt+k1/2.d0, t + dt/2.d0,r,k2,gamma,pinf)
      CALL RKFUNC(yt+k2/2.d0, t + dt/2.d0,r,k3,gamma,pinf)  
      CALL RKFUNC(yt+k3, t + dt,r,k4,gamma,pinf)
      ! Compute RK time step with the k's
      yout = yt + dt*(k1 + 2.0*k2 + 2.0*k3 + k4)/6.0
      return
      end
c      =======================================================

c      =======================================================
      subroutine RKFUNC(yt,t,r,ki,gamma,pinf)
      implicit double precision (a-h,o-z)
      dimension yt(1:4)
      double precision, dimension(4) :: ki(1:4)
      
      uz = yt(2)/yt(1)
      ur = yt(3)/yt(1)
      p = (gamma - 1.0)*(yt(4) - 0.5*yt(1)*(ur**2 + uz**2)) - gamma*pinf
      
      ki(1) = -yt(3)/r
      ki(2) = -yt(3)*yt(2)/yt(1)
      ki(3) = -yt(3)**2/(yt(1)*r)
      ki(4) = ur*(yt(4) + p)/r
      
      return
      end
c      =======================================================

