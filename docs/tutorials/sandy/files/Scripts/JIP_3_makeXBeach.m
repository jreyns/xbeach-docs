%% XBeach JIP tutorial: how to set-up a storm-impact model?
% Step 3: make the actually XBeach grid
% v0.1  Nederhoff   Nov-15   
clear all, close all, clc

%% 0. Define
% A. Directory
destin          = 'e:\Projecten\TKI\Data\Step3_makeXB\';
destinbathy     = 'e:\Projecten\TKI\Data\Step1_makebathy\';
destWL          = 'e:\Projecten\TKI\Data\Step2_makebc\Model\Waterlevel\';
destwaves       = 'e:\Projecten\TKI\Data\Step2_makebc\Model\Waves sp2\';
destout         = 'e:\Projecten\TKI\XBeach model\Version01_30Nov15\'; mkdir(destout);

% B. Model
dxmin               = 2;
dymin               = 5;
outputformat        = 'netcdf';
        
%% 1. Determine bathy and bc
% A. Bathymetry
cd(destinbathy)
load 'bathy_final.mat'

% B. Read tide
cd(destWL)
load 'tide.txt'
T                       = 3 * 24 * 3600 % 3 days in seconds
tide_time               = tide(:,1);
tide_front              = tide(:,2);
tide_back               = tide(:,3)  ;  

%% 2. Closure
rotation_xb         = rotation/pi*180;

xbm = xb_generate_model(...
    'bathy',...
        {'x', X, 'y', Y, 'z', Z_pre,... 
        'xgrid', {'dxmin',dxmin},... 
        'ygrid', {'dymin',dymin},...
        'ygrid', {'area_size',1000},...
        'rotate', rotation_xb, ...
        'crop', false,...
        'world_coordinates',true,...
        'finalise', {'actions', {'seaward_flatten', 'seaward_extend'},'zmin',-25}}, ...
'tide',... 
        {'time', tide_time, ... 
        'back', tide_back, ...
        'front', tide_front}, ... 
'settings', ...
        {'outputformat',outputformat,... 
        'instat',5,...
        'bcfile','loclist.txt',...
        'morfac', 10,...
        'morstart', 0, ...
        'CFL', 0.7,...
        'front', 'abs_2d', ...
        'back', 'abs_2d', ...
        'mpiboundary','x',...
        'thetamin', 0, ...
        'thetamax', 180, ...
        'dtheta',10,...
        'thetanaut', 1, ...
        'tstop', T, ...
        'tstart', 0,...
        'tintg', T/72,...
        'tintm', T/6,...
        'D50', .0003,...
        'D90', .0004,...
        'epsi',-1,...              
        'facua',0.10,...
        'bedfriction', 'manning',...
        'meanvar',          {'zb', 'zs', 'H', 'ue', 've'} ,...
        'globalvar',        {'zb', 'zs', 'H', 'ue', 've','sedero'}},...
        'write', false,...
        'createwavegrid',false);         

%% 4. Aanpassingen maken
% A. Get grid
xgrid                   = xs_get(xbm,'xfile.xfile');
ygrid                   = xs_get(xbm,'yfile.yfile');
zgrid                   = xs_get(xbm,'depfile.depfile');

% B. Maximum and minimum values       
id1 = find(zgrid > 10);
for i = 1:length(id1)
    zgrid(id1(i)) = 10;
end

id2 = find(zgrid < -30);
for i = 1:length(id2)
    zgrid(id2(i)) = -30;
end
        
% C. Straight boundaries
[nx ny]                             = size(zgrid);
roundnumber                         = 5;
first                               = 1;
second                              = roundnumber;
third                               = nx-(roundnumber-1);
four                             	= nx;
five                                = ny - (roundnumber-1);
six                                 = ny;
zgrid([first:second],:)             = repmat(zgrid(second,:),[roundnumber,1]); 
zgrid([(third:four)],:)             = repmat(zgrid((third),:),[roundnumber,1]);
zgrid(:,[five:six])                 = repmat(zgrid(:,six),[1,roundnumber]);
xbm                                 = xs_set(xbm, 'depfile.depfile', zgrid);

% E. Make barrier roughness
cd(destin);
load poly.mat
bedfric                 = ones(size(zgrid))*0.02;
barrierisland           = inpolygon(xgrid,ygrid,poly.barrier.x,poly.barrier.y);
bedfric(barrierisland)  = 0.04;
xbm                     = xs_set(xbm, 'bedfricfile', xs_set([], 'bedfricfile', bedfric)); 

% F. Save
cd(destout);
data = [destout, '\xbm', '.mat']
save(data,'xbm')  
copyfile(destwaves,destout,'f')        
xb_write_input([destout '\params.txt'], xbm)
bedfric                   = xs_get(xbm,'bedfricfile.bedfricfile');
save('bedfricfile.txt', 'bedfric', '-ascii')