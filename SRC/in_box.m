function [I,boxCorners,XYZ] = in_box(lat,lon,depth,hlat,hlon,hdepth,hM,hstrike,hdip,W,save_out,fn,M,t)

% indicate all points [lat, lon, depth] that lie inside a rectangular prism
% of length and depth depfined by Reasenberg and Jones scaling based on the
% magnitude specified (hM) with a width (W) and rotated according to the
% strike (hstrike) and dip (hdip) centered on the hypocenter (hlat,hlon,
% hdepth). Make sure all input is in km where appropriate. Outputs are the
% indices of the points that lie in the box and the box corners (8 by 3,
% eath centric oordinates).

% save_out,fn,M,t are optional

% Author: Kelian Dacsher-Cousineau
% e-mail: kdascher@ucsc.ed
% Release date: 01/29/20



% convert to km
wgs84       = wgs84Ellipsoid('kilometer');
[x,y,z]     = geodetic2ecef(wgs84,lat, lon, -depth ); XYZ = [x,y,z]; 
[xh,yh,zh]  = geodetic2ecef(wgs84,hlat,hlon,-hdepth);

% determine dimension based on hM
scaling     = @(MOMENT_MAGNITUDE) 10^(0.62*MOMENT_MAGNITUDE-2.57);
L           = scaling(hM);

if L < W % the box is wider than it is long revert to a spherical search
    I = sum(([x,y,z]-[xh,yh,zh]).^2,2) < W^2;
    boxCorners = nan;
    warning('Box would be wider than it is long - working with a sphere instead')
else
    % make flat lying box
    xt = repmat([-L/2,-L/2, L/2, L/2],1,2)';
    yt = repmat([-L/2, L/2, L/2,-L/2],1,2)';
    zt  = [1 1 1 1 -1 -1 -1 -1]'*W;
    XYZt = [xt,yt,zt];
    
    % rotate box according to dip
    %
    XYZt = XYZt*rotx(-hdip);    % rotate to dip
    XYZt = XYZt*rotz(hstrike);  % rate to strike
    
    XYZt = XYZt*roty(hlat-90);
    XYZt = XYZt*rotz(-hlon);
    
    % center box on the hypocenter
    boxCorners = XYZt+ones(8,1)*[xh,yh,zh];  
    I = inhull(XYZ,boxCorners);
end

if nargin==14  && save_out
    catS = [lon(I),lat(I),decyear(t(I)),nan(size(t(I))),nan(size(t(I))),M(I),depth(I)];
    ms   = [hlon,hlat,decyear(t(find(M==hM,1,'first'))),nan            ,nan            ,hM  ,hdepth];
    save([fn,   '.mat'],'catS');
    save([fn,'_ms.mat'],'ms');
end

end



function in = inhull(testpts,xyz,tess,tol)
% inhull: tests if a set of points are inside a convex hull
% usage: in = inhull(testpts,xyz)
% usage: in = inhull(testpts,xyz,tess)
% usage: in = inhull(testpts,xyz,tess,tol)
%
% arguments: (input)
%  testpts - nxp array to test, n data points, in p dimensions
%       If you have many points to test, it is most efficient to
%       call this function once with the entire set.
%
%  xyz - mxp array of vertices of the convex hull, as used by
%       convhulln.
%
%  tess - tessellation (or triangulation) generated by convhulln
%       If tess is left empty or not supplied, then it will be
%       generated.
%
%  tol - (OPTIONAL) tolerance on the tests for inclusion in the
%       convex hull. You can think of tol as the distance a point
%       may possibly lie outside the hull, and still be perceived
%       as on the surface of the hull. Because of numerical slop
%       nothing can ever be done exactly here. I might guess a
%       semi-intelligent value of tol to be
%
%         tol = 1.e-13*mean(abs(xyz(:)))
%
%       In higher dimensions, the numerical issues of floating
%       point arithmetic will probably suggest a larger value
%       of tol.
%
%       DEFAULT: tol = 0
%
% arguments: (output)
%  in  - nx1 logical vector
%        in(i) == 1 --> the i'th point was inside the convex hull.
%  
% Example usage: The first point should be inside, the second out
%
%  xy = randn(20,2);
%  tess = convhulln(xy);
%  testpoints = [ 0 0; 10 10];
%  in = inhull(testpoints,xy,tess)
%
% in = 
%      1
%      0
%
% A non-zero count of the number of degenerate simplexes in the hull
% will generate a warning (in 4 or more dimensions.) This warning
% may be disabled off with the command:
%
%   warning('off','inhull:degeneracy')
%
% See also: convhull, convhulln, delaunay, delaunayn, tsearch, tsearchn
%
% Author: John D'Errico
% e-mail: woodchips@rochester.rr.com
% Release: 3.0
% Release date: 10/26/06
% get array sizes
% m points, p dimensions
p = size(xyz,2);
[n,c] = size(testpts);
if p ~= c
  error 'testpts and xyz must have the same number of columns'
end
if p < 2
  error 'Points must lie in at least a 2-d space.'
end
% was the convex hull supplied?
if (nargin<3) || isempty(tess)
  tess = convhulln(xyz);
end
[nt,c] = size(tess);
if c ~= p
  error 'tess array is incompatible with a dimension p space'
end
% was tol supplied?
if (nargin<4) || isempty(tol)
  tol = 0;
end
% build normal vectors
switch p
  case 2
    % really simple for 2-d
    nrmls = (xyz(tess(:,1),:) - xyz(tess(:,2),:)) * [0 1;-1 0];
    
    % Any degenerate edges?
    del = sqrt(sum(nrmls.^2,2));
    degenflag = (del<(max(del)*10*eps));
    if sum(degenflag)>0
      warning('inhull:degeneracy',[num2str(sum(degenflag)), ...
        ' degenerate edges identified in the convex hull'])
      
      % we need to delete those degenerate normal vectors
      nrmls(degenflag,:) = [];
      nt = size(nrmls,1);
    end
  case 3
    % use vectorized cross product for 3-d
    ab = xyz(tess(:,1),:) - xyz(tess(:,2),:);
    ac = xyz(tess(:,1),:) - xyz(tess(:,3),:);
    nrmls = cross(ab,ac,2);
    degenflag = false(nt,1);
  otherwise
    % slightly more work in higher dimensions, 
    nrmls = zeros(nt,p);
    degenflag = false(nt,1);
    for i = 1:nt
      % just in case of a degeneracy
      % Note that bsxfun COULD be used in this line, but I have chosen to
      % not do so to maintain compatibility. This code is still used by
      % users of older releases.
      %  nullsp = null(bsxfun(@minus,xyz(tess(i,2:end),:),xyz(tess(i,1),:)))';
      nullsp = null(xyz(tess(i,2:end),:) - repmat(xyz(tess(i,1),:),p-1,1))';
      if size(nullsp,1)>1
        degenflag(i) = true;
        nrmls(i,:) = NaN;
      else
        nrmls(i,:) = nullsp;
      end
    end
    if sum(degenflag)>0
      warning('inhull:degeneracy',[num2str(sum(degenflag)), ...
        ' degenerate simplexes identified in the convex hull'])
      
      % we need to delete those degenerate normal vectors
      nrmls(degenflag,:) = [];
      nt = size(nrmls,1);
    end
end
% scale normal vectors to unit length
nrmllen = sqrt(sum(nrmls.^2,2));
% again, bsxfun COULD be employed here...
%  nrmls = bsxfun(@times,nrmls,1./nrmllen);
nrmls = nrmls.*repmat(1./nrmllen,1,p);
% center point in the hull
center = mean(xyz,1);
% any point in the plane of each simplex in the convex hull
a = xyz(tess(~degenflag,1),:);
% ensure the normals are pointing inwards
% this line too could employ bsxfun...
%  dp = sum(bsxfun(@minus,center,a).*nrmls,2);
dp = sum((repmat(center,nt,1) - a).*nrmls,2);
k = dp<0;
nrmls(k,:) = -nrmls(k,:);
% We want to test if:  dot((x - a),N) >= 0
% If so for all faces of the hull, then x is inside
% the hull. Change this to dot(x,N) >= dot(a,N)
aN = sum(nrmls.*a,2);
% test, be careful in case there are many points
in = false(n,1);
% if n is too large, we need to worry about the
% dot product grabbing huge chunks of memory.
memblock = 1e6;
blocks = max(1,floor(n/(memblock/nt)));
aNr = repmat(aN,1,length(1:blocks:n));
for i = 1:blocks
   j = i:blocks:n;
   if size(aNr,2) ~= length(j),
      aNr = repmat(aN,1,length(j));
   end
   in(j) = all((nrmls*testpts(j,:)' - aNr) >= -tol,1)';
end

end
