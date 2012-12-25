clc
clear all

disp('********************************************************');
disp('****    3D Mesh Generator for the Poisson Solver    ****');
disp('********************************************************');
disp(' ')

L = 1.0;   % Size of the cubical Cavity

nX = input('Number of nodes on one side of the cubical problem domain (enter an odd integer) = ');
disp(' ')
cluster = input('Clustering value (enter a positive value, zero means no clustering)  = ');

specifiedPressure = 0.0;
pressureNode = 0;      % The node at the origin is the zero pressure node.

disp(' ')

%nMonitorPoints = input('Number of monitor points = ');
%
%for i = 1:nMonitorPoints 
%   monitorCoord(i,1) = input(['x coordinate of monitor point ', num2str(i, '%2d'), ' = ']);
%   monitorCoord(i,2) = input(['y coordinate of monitor point ', num2str(i, '%2d'), ' = ']);
%   monitorCoord(i,3) = input(['z coordinate of monitor point ', num2str(i, '%2d'), ' = ']);
%end


NN = nX*nX*nX;
NE = (nX-1)*(nX-1)*(nX-1);
NCN = NN;
coord = zeros(nX,1);


% Calculate coordinates of one edge of the Cavity
if cluster == 0      % Uniform mesh, no clustering
   dx = L / (nX-1);  % Constant spacing between the nodes.
   for i = 1:nX
      coord(i) = 0 + (i-1) * dx;
   end
else                 % Nonuniform mesh.
                     % sinh() function is used for clustering.
   MAX = sinh(cluster);
   for i = 1:(nX+1)/2                   % Work with half of the Cavity length
      xx = (i-1) / ((nX-1)/2);          % 0 < xx < 1  (linear distribution)
      xxx = sinh(cluster * xx);         % 0 < xxx < MAX  (nonlinear distribution)
      coord(i) = L/2 / MAX * xxx;       % Rescale in [0,L/2]
   end
   
   % Take mirror image of the calculated clustered coordinates
   for i = (nX+1)/2 + 1:nX
      coord(i) = L - coord(nX+1-i);
   end
end 



% Creating the input file for code
disp(' ')
disp(' ')
disp('Writing the input file. This may take some time for large meshes ...');

outputFile = fopen('poisson.inp','wt');

fprintf(outputFile,'This input file is generated by the cavityMeshGenerator.m code\n');    

fprintf(outputFile,'================================================\n');
fprintf(outputFile,'eType         : 3\n');
fprintf(outputFile,'NE            : %d\n', NE);
fprintf(outputFile,'NN            : %d\n', NN);
fprintf(outputFile,'NEN           : 8\n');
fprintf(outputFile,'NGP           : 8\n');
fprintf(outputFile,'solverIterMax : 1000\n');
fprintf(outputFile,'solverTol     : 1e-10\n');
fprintf(outputFile,'axyFunc       : 1.0\n');
fprintf(outputFile,'fxyFunc       : 0.0\n');


fprintf(outputFile,'================================================\n');
fprintf(outputFile,'Node#           x               y               z\n');
nodeCounter = 0;
for k = 1:nX
   for j = 1:nX
      for i = 1:nX
          x = coord(i);
          y = coord(j);
          z = coord(k);
          fprintf(outputFile,'%5d%16.7f%16.7f%16.7f\n', nodeCounter, x, y, z);
          nodeCounter = nodeCounter + 1;
      end
   end
end


fprintf(outputFile,'================================================\n');
fprintf(outputFile,'Elem#     node1     node2      node3      node4      node5      node6      node7      node8\n');
elemCounter = 0;
for k = 0:nX-2
   for j = 0:nX-2
      for i = 0:nX-2
          n0 = k*nX*nX + j*nX + i;
          n1 = n0 + 1;
          n2 = n1 + nX;
          n3 = n2 - 1;
          n4 = n0 + nX*nX;
          n5 = n4 + 1;
          n6 = n5 + nX;
          n7 = n6 - 1;
          
          fprintf(outputFile,'%7d%11d%11d%11d%11d%11d%11d%11d%11d', elemCounter, n0, n1, n2, n3, n4, n5, n6, n7);
          
          elemCounter = elemCounter + 1;
          
          fprintf(outputFile,'\n');
      end
   end
end


fprintf(outputFile,'================================================\n');
fprintf(outputFile,'BCs (Number of specified BCs, their types and strings)\n');
fprintf(outputFile,'nBC       : 1\n');                    
fprintf(outputFile,'BC 1      : 1  0.0\n');

nEBCnodes = (nX-2)*(nX-2)*6 + (nX-2)*12 + 8;
nNBCfaces = 0;

fprintf(outputFile,'================================================\n');
fprintf(outputFile,'nEBCnodes : %d\n', nEBCnodes);
fprintf(outputFile,'nNBCfaces : %d\n', nNBCfaces);

fprintf(outputFile,'================================================\n');
fprintf(outputFile,'EBC Data (Node#  BC No.)\n');



% BC of the bottom (z=0) wall
k=0;
for j = 0:nX-1
  for i = 0:nX-1
     node = k*nX*nX + j*nX + i;
     fprintf(outputFile,'%7d     1\n', node);
  end
end


% BC of the left (y=0) wall
j=0;
for k = 1:nX-2
  for i = 0:nX-1
     node = k*nX*nX + j*nX + i;
     fprintf(outputFile,'%7d     1\n', node);
  end
end


% BC of the right (y=L) wall
j = nX-1;
for k = 1:nX-2
  for i = 0:nX-1
     node = k*nX*nX + j*nX + i;
     fprintf(outputFile,'%7d     1\n', node);
  end
end



% BC of the back (x=0) wall
i=0;
for k = 1:nX-2
  for j = 1:nX-2
     node = k*nX*nX + j*nX + i;
     fprintf(outputFile,'%7d     1\n', node);
  end
end



% BC of the front (x=L) wall
i = nX-1;
for k = 1:nX-2
  for j = 1:nX-2
     node = k*nX*nX + j*nX + i;
     fprintf(outputFile,'%7d     1\n', node);
  end
end



% BC of the top (z=L) wall
k=nX-1;
for j = 0:nX-1
  for i = 0:nX-1
     node = k*nX*nX + j*nX + i;
     fprintf(outputFile,'%7d     1\n', node);
  end
end



fprintf(outputFile,'================================================\n');
fprintf(outputFile,'NBC Data (Elem#  Face#  BC No.)\n');
fprintf(outputFile,'================================================\n');




%fprintf(outputFile,'================================================\n');
%fprintf(outputFile,'nMonitorPoints : %3d\n', nMonitorPoints);
%fprintf(outputFile,'Monitor Points (Point# Coord_X Coord_Y Coord_Z) \n');
%fprintf(outputFile,'================================================\n');
%for i = 1:nMonitorPoints
%   fprintf(outputFile,'%3d  %f   %f   %f\n', i-1, monitorCoord(i,1), monitorCoord(i,2), monitorCoord(i,3));
%end


fclose(outputFile); 

disp(' ')
disp('Input file poisson.inp is created.');
disp(' ')
