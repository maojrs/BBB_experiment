c
c      =======================================================
      subroutine src2(meqn,mbc,mx,my,xlower,ylower,
     &                 dx,dy,q,maux,aux,t,dt)
c      =======================================================
c
      ! Declare implicit, state, auxiliary and input/output variables
      implicit double precision (a-h,o-z)
      dimension    q(meqn,1-mbc:mx+mbc,1-mbc:my+mbc)
      dimension  aux(maux,1-mbc:mx+mbc,1-mbc:my+mbc)
      dimension  yt(1:4), ys(1:4), yout(1:4)
c
c     # If method(5)=0 then this routine is never called, but its
c     # existence may be required by some compilers.

      ! Loop over all cells
      do i=1-mbc,mx+mbc 
        xcell = xlower + (i-0.5d0)*dx 
        do j=1-mbc,my+mbc 
            r = ylower + (j-0.5d0)*dy + 5.d0*dy ! Artificial extra to avoid almost singular source terms
            ! Equation of state variables             
            gamma = aux(1,i,j)
            pinf = aux(2,i,j)
            omega = aux(3,i,j)
            
            ! Save input variables
            yt(1) = q(1,i,j)
            yt(2) = q(2,i,j)
            yt(3) = q(3,i,j)
            yt(4) = q(4,i,j)
            
            ! Calculate useful parameters
            uz = yt(2)/yt(1)
            ur = yt(3)/yt(1)
            ekt = 0.5*yt(1)*(uz*uz + ur*ur)
            pt = (gamma - 1.0)*(yt(4) - ekt) - gamma*pinf
            del = dt*ur/r
            
            ! Calculate iteration based on exact solution
            yout(1) = yt(1)*dexp(-del)
            yout(2) = uz*yout(1)
            yout(3) = ur*yout(1)
            
            pout = pt*dexp(-del*gamma) - pinf*(1.d0 - dexp(-del*gamma)) 
     &    - ekt*(dexp(-del) - dexp(-del*gamma))
     
            yout(4) = (pout + gamma*pinf)/(gamma-1) + 
     &    0.5*yout(1)*(uz*uz + ur*ur)
     
            ! Save to output variables
            q(1,i,j) = yout(1)
            q(2,i,j) = yout(2)
            q(3,i,j) = yout(3)
            q(4,i,j) = yout(4)
        end do
      end do
      
      return
      end

      ! RK4 subroutine if required (not required in this code)
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

