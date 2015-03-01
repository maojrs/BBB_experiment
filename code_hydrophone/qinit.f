c
c
c
c     =====================================================
       subroutine qinit(meqn,mbc,mx,my,xlower,ylower,
     &                   dx,dy,q,maux,aux)
c     =====================================================
c
c     # Set initial conditions for q.
c
       ! Declare implicit, states and auxiliary variables
       implicit double precision (a-h,o-z)
       dimension q(meqn,1-mbc:mx+mbc,1-mbc:my+mbc)
       dimension aux(maux,1-mbc:mx+mbc,1-mbc:my+mbc)
       ! Declare pressure array
       dimension p(1-mbc:mx+mbc)

       ! Load commno block parameters (EOS parameters and densities)
       common /param/ gammagas, gammaplas, gammawat
       common /param/ pinfgas,pinfplas,pinfwat
       common /param/ omegas,omeplas,omewat
       common /param/ rhog,rhop,rhow
 
       ! Calculate pi
       pi = 4.d0*datan(1.d0)
       

      ! Open all gauge and initial data files to load info from in 
      ! whole program
      open (11,file="../_gauges/a-pgauge1.dat",action="write",
     & status="replace")
      open (12,file="../_gauges/a-pgauge2.dat",action="write",
     & status="replace")
      open (13,file="../_gauges/a-pgauge3.dat",action="write",
     & status="replace")
      open (14,file="../_gauges/a-pgauge4.dat",action="write",
     & status="replace")
      open (25,file="../_initfiles/a-pICtime.dat",action="read",
     & status="old") 

      ! Write initial conditions to have constant pressure (p_atm) across materials
      p0 = 101325.d0 ! atmospheric pressure
      ! Make p array contant everywhere
      p = p0  
      
      ! NOTE the initial conditions vary for different material arrangement
      ! Gas in contact with water, and water in contact with plastic
      ! is different than Gas in contact with plastic , and plastic in contact
      ! with water
      
      ! Energy in water and plastic in gas-water-plastic (gwp) arrangement
      ! Calculate energy and speed of sound in gas steady state
      Egas0 = (p0 + gammagas*pinfgas)/(gammagas - 1.d0)  
      c0 = sqrt(gammagas*p0/rhog) 
      
      ! Defines jump in energies to make pressure equal accross interfaces using SGEOS
      ! Energy in water an plastic in air-water-plastic arrangement
      EgwpWat = (Egas0*(gammagas - 1.d0) - gammagas*pinfgas
     & + gammawat*pinfwat)/(gammawat - 1.d0)         
      EgwpPlas = (EgwpWat*(gammawat - 1.d0) - gammawat*pinfwat
     & + gammaplas*pinfplas)/(gammaplas - 1.d0)   
      ! Energy in water an plastic in air-plastic-water arrangement
      EgpwPlas = (Egas0*(gammagas - 1.d0) - gammagas*pinfgas
     & + gammaplas*pinfplas)/(gammaplas - 1.d0)         
      EgpwWat = (EgpwPlas*(gammaplas - 1.d0) - gammaplas*pinfplas
     & + gammawat*pinfwat)/(gammawat - 1.d0)   
      
      ! Loop over all grid cells
      do 150 i=1-mbc,mx+mbc
        xcell = xlower + (i-0.5d0)*dx
        do 151 j=1-mbc,my+mbc
          ycell = ylower + (j-0.5d0)*dy
          
          ! Adjust initial conditions depending if it's gas,PS or water using the correct
          ! energies just calculated
          if (aux(1,i,j) == gammagas) then
            q(1,i,j) = rhog*(p(i)/p0)**(1/gammagas) 
            q(2,i,j) = (2/(gammagas - 1.0))*(-c0 + 
     & sqrt(gammagas*p(i)/q(1,i,j)))
            q(3,i,j) = 0.d0
            !q(2,i,j) = 0.d0
            q(4,i,j) = (p(i) + gammagas*pinfgas)/(gammagas - 1.0) +
     & (q(2,i,j)**2 + q(3,i,j)**2)/(2.0*q(1,i,j))
     
         else if (aux(1,i,j) == gammaplas) then
            q(1,i,j) = rhop
            q(2,i,j) = 0.d0
            q(3,i,j) = 0.d0
            ! make sure pressure jump is zero across interface using SGEOS (check correct order of interfaces)
            q(4,i,j) = 1.d0*EgwpPlas
     
         else if (aux(1,i,j) == gammawat) then
            q(1,i,j) = rhow
            q(2,i,j) = 0.d0
            q(3,i,j) = 0.d0
            ! make sure pressure jump is zero across interface using SGEOS (check correct order of interfaces)
            q(4,i,j) = 1.d0*EgwpWat

          end if
  151    continue	  
  150  continue
       return
       end

