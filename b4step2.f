c     ============================================
      subroutine b4step2(mbc,mx,my,meqn,q,
     &            xlower,ylower,dx,dy,t,dt,maux,aux)
c     ============================================
c
c     # called from claw2 before each call to step2.
c     # use to set time-dependent aux arrays or perform other tasks
c     # which must be done every time step.

c
c     
      ! Declare implicit, states and auxiliary variables
      implicit double precision (a-h,o-z)
      dimension q(meqn,1-mbc:mx+mbc,1-mbc:my+mbc)
      dimension aux(maux,1-mbc:mx+mbc,1-mbc:my+mbc)

      ! Load common blocks (EOS parameters and densities)    
      common /param/ gammagas, gammaplas, gammawat
      common /param/ pinfgas,pinfplas,pinfwat
      common /param/ rhog,rhop,rhow
      
      ! Write q variable to aux array
      do jj=1-mbc,my+mbc
        do ii=1-mbc,mx+mbc
            aux(4,ii,jj) = q(1,ii,jj)
            aux(5,ii,jj) = q(2,ii,jj)
            aux(6,ii,jj) = q(3,ii,jj)
            aux(7,ii,jj) = q(4,ii,jj)
        end do
      end do 
c
      ! GAUGES for pressure (choose point to see pressure as a function of time at that point)
      ! Several gauges added in different locations
      
      ! GAUGE 1
      xcell = -0.015
      ycell = 0.0005
      i = floor((xcell - xlower)/dx + 0.5)
      j = floor((ycell - ylower)/dy + 0.5)
      ! Calculate pressure at that point
      gamma = aux(1,i,j)
      gamma1 = aux(1,i,j) - 1.0
      pinf = aux(2,i,j)
      rho = q(1,i,j)           ! density
      momx = q(2,i,j)           ! momentum
      momy = q(3,i,j)
      ene = q(4,i,j)           ! energy
      p = gamma1*(ene - 0.5*(momx*momx + momy*momy)/rho)
      p = p - gamma*pinf 
      ! Write Gauge data to file
      write (11,*) t, p
      
      ! GAUGE 2
      xcell = -0.0065
      ycell = 0.0005
      i = floor((xcell - xlower)/dx + 0.5)
      j = floor((ycell - ylower)/dy + 0.5)
      ! Calculate pressure at that point
      gamma = aux(1,i,j)
      gamma1 = aux(1,i,j) - 1.0
      pinf = aux(2,i,j)
      rho = q(1,i,j)           ! density
      momx = q(2,i,j)           ! momentum
      momy = q(3,i,j)
      ene = q(4,i,j)           ! energy
      p = gamma1*(ene - 0.5*(momx*momx + momy*momy)/rho)
      p = p - gamma*pinf 
      ! Write Gauge data to file
      write (12,*) t, p

      ! GAUGE 3
      xcell = 0.0065
      ycell = 0.0005
      i = floor((xcell - xlower)/dx + 0.5)
      j = floor((ycell - ylower)/dy + 0.5)
      ! Calculate pressure at that point 
      gamma = aux(1,i,j)
      gamma1 = aux(1,i,j) - 1.0
      pinf = aux(2,i,j)
      rho = q(1,i,j)           ! density
      momx = q(2,i,j)           ! momentum
      momy = q(3,i,j)
      ene = q(4,i,j)           ! energy
      p = gamma1*(ene - 0.5*(momx*momx + momy*momy)/rho)
      p = p - gamma*pinf 
      ! Write Gauge data to file
      write (13,*) t, p

      ! GAUGE 4
      xcell = 0.0065
      ycell = 0.0016
      i = floor((xcell - xlower)/dx + 0.5)
      j = floor((ycell - ylower)/dy + 0.5)
      ! Calculate pressure at that point
      gamma = aux(1,i,j)
      gamma1 = aux(1,i,j) - 1.0
      pinf = aux(2,i,j)
      rho = q(1,i,j)           ! density
      momx = q(2,i,j)           ! momentum
      momy = q(3,i,j)
      ene = q(4,i,j)           ! energy
      p = gamma1*(ene - 0.5*(momx*momx + momy*momy)/rho)
      p = p - gamma*pinf 
      ! Write Gauge data to file
      write (14,*) t, p
      
      return
      end

