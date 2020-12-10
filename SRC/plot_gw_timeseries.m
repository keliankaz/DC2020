% ------- Traffic Light System by Laura Gulia and Stefan Wiemer -----------
% -------------------------------------------------------------------------

% May 10, 2020: Adapted by Kelian Dascher-Cousnineau for a sensitivity analysis of the
% results presented in Gulia and Wiemer, 2019.

%%
% The method we propose is a real-time tool to discriminate between foreshocks and aftershocks

% This code calculates a background reference b-value for a subcatalog of events.
% This background b-value is used to calculate the variation in percentage
% from the reference, following a Magnitide M>=6. The analysis is performed using a moving-window
% approach, moved forward event by event. The window length is defined by paratemeters Npre and Npost;
% after the M>=6 quake, due to completeness issue, the removal a 'blackout
% period'(defined in the input parameter section) is required for each sequence,
% an input based on data quality analysis. 
%
% We then define a simple level of concern, expressed as a traffic light, depending on such value:

% Red  <10% change
% Yellow  +/-10% change
% Green >10% change

% The events in the subcatalog are selected according to the method by Gianfranco Vannucci, described in
% Gulia et al. (GRL, 2018)
%
% CopyRight: Laura Gulia & Stefan Wiemer, ETH Zurich
% date: 2019, tested under Matlab 2018a 
%
%% 

function [brel,t] = plot_gw_timeseries(varargin)

% sample input:
% plot_gw_timeseries()
% plot_gw_timeseries('Earthquake','Ridgecrest','ForeshockStrike', etc) % do
% this

% done-ish
p = parse_input(varargin);
p = p.Results;

% this should probably be done better but is ok now
earthquakeCatalog = assemble_catalog(p.Earthquake); % very earthquake specific (e.g. parsing regional catalogs)

% should work but probably wont
[cat_Reg,catS_fs,ms_fs,catS_ms,ms_ms] = build_catalog(earthquakeCatalog,p.fsM,p.Mc0,p.Width, ...
                                                      p.ForeshockStrike,p.ForeshockDip, ...
                                                      p.MainshockStrike,p.MainshockDip);
                              
Tms = ms_fs(3);
Tms2= ms_ms(3);

% done
days            = p.ForeshockBlindTime;
days_post2      = p.MainshockBlindTime;
Tmin            = p.CatalogStartDate;
Tmax            = p.CatalogEndDate;
corr            = p.MaxCurvatureCorrection;

% should work - but probably wont
warning off % embrace the chaos by ignoring it
[t_foreshock,~,brel_foreshock] = partial_time_series(Tms,Tms2,days,days_post2,cat_Reg,ms_fs,Tmin,Tmax,catS_fs, corr, p.McExpertChoice);
[t_mainshock,~,brel_mainshock] = partial_time_series(Tms,Tms2,days,days_post2,cat_Reg,ms_ms,Tmin,Tmax,catS_ms, corr, p.McExpertChoice);
warning on

% this should work but will need to be pretti-ed up
t = [t_foreshock(t_foreshock<=Tms2),      t_mainshock(t_mainshock>Tms2)];
brel = [brel_foreshock(2,t_foreshock<=Tms2), brel_mainshock(2,t_mainshock>Tms2)]*100;
decyear2dt = @(x) datetime(datenum(datetime(floor(x), 1, 1) + years(x-floor(x))),'ConvertFrom','datenum');
dt = decyear2dt(t);

if p.PlotOutput
    if p.NewFigure; figure; hold on; end
    
    plot(dt,brel,p.PLotOptions{:})
    
    ylabel('Relative b-value (%)')
    drawnow
end



    function    [p,notUsingDefault] = parse_input(input)
        

        p =  inputParser;
        p.FunctionName = 'plot_gw_timeseries';
        
        % default earthquake:
        defaultEarthquake       = 'Ridgecrest';
        defaultfsM              = 6.4;
        defaultmsM              = 7.1;
        expectedEarthquakes     = {'Ridgecrest','Puerto_Rico'}; 
        defaultForeshockStrike  = 137;
        defaultForeshockDip     = 87;
        defaultMainshockStrike  = 321;
        defaultMainshockDip     = 81;
        
        % default values
        default_Mc0  = 0; 
        default_corr = 0.2;
        
        default_expert_choice.pre = 'none';
        default_expert_choice.post= 'none';
        default_expert_choice.post2='none'; 
        
        default_Tmin = 1950;
        default_days = 0.05;
        default_days_post2 = 3;
        default_Tmax = 3000;
        
        default_width = 3; 
        
        default_newfig = true;
        default_plotOut= true;
        default_plotOpt= {'-.k'};
        
        % check if inputs are numbers and positive
        numericErrorMessage     = @(x) sprintf('%s input value must be positive, scalar, and numerical.',class(x));
        numericValidationFcn    = @(x) assert(isnumeric(x), numericErrorMessage(x));
        
        % check if inputs are numbers and positive and length 2
        numeric2ErrorMessage     = @(x) sprintf('%s input value must be scalar, numerical and of length 2.',class(x));
        numeric2ValidationFcn    = @(x) assert(isnumeric(x) && length(x) == 2, numeric2ErrorMessage(x));
        
        % check if inpput is one of a string
        stringErrorMessage      = @(x) ['Input must be one of:', sprintf(' ''%s''',x{:})];
        stringValidationFcn     = @(x,y) assert(any(strcmp(x,y)),stringErrorMessage(y));
        
        %% add parameters (in respective order)
        addParameter(p,'Earthquake',                defaultEarthquake,          @(x) stringValidationFcn(x,expectedEarthquakes));
        addParameter(p,'fsM',                       defaultfsM,                 numericValidationFcn);
        addParameter(p,'msM',                       defaultmsM,                 numericValidationFcn);
        addParameter(p,'ForeshockStrike',           defaultForeshockStrike,     numericValidationFcn);
        addParameter(p,'ForeshockDip',              defaultForeshockDip,        numericValidationFcn);
        addParameter(p,'MainshockStrike',           defaultMainshockStrike,     numericValidationFcn);
        addParameter(p,'MainshockDip',              defaultMainshockDip,        numericValidationFcn);
        
        addParameter(p,'Mc0',                             default_Mc0,         numericValidationFcn);
        addParameter(p,'MaxCurvatureCorrection',          default_corr,         numericValidationFcn);
        addParameter(p,'McExpertChoice',                  default_expert_choice)
        addParameter(p,'CatalogStartDate',                default_Tmin,         numericValidationFcn);
        addParameter(p,'CatalogEndDate',                  default_Tmax,         numericValidationFcn);
        addParameter(p,'ForeshockBlindTime',              default_days,         numericValidationFcn);
        addParameter(p,'MainshockBlindTime',              default_days_post2,   numericValidationFcn);
        addParameter(p,'Width',                           default_width);
        
        addParameter(p,'NewFigure',                       default_newfig);
        addParameter(p,'PLotOptions',                     default_plotOpt);
        addParameter(p,'PlotOutput',                      default_plotOut);
        
        parse(p,input{:});
        
        if ~(length(p.Parameters) == length(p.UsingDefaults))
            
            notUsingDefault = cell(1,length(p.Parameters)-length(p.UsingDefaults));
            for n = 1:length(notUsingDefault)
                ind = ~any(strcmp(p.Parameters{n},p.UsingDefaults));
                notUsingDefault{n} = string(p.Parameters{ind});
            end
            
        else
            notUsingDefault = {};
        end
        
    end

end

function c = assemble_catalog(eq_of_interest)

if strcmp('Ridgecrest', eq_of_interest)
    % load Shelly's catalog:
    load('Shelly2019.mat') %% edit this
    cShelly       = shelly_catalog; %% edit this
    cS            = table;
    cS.Mag        = cShelly.mag;
    cS.Lat        = cShelly.lat;
    cS.Long       = cShelly.lon;
    cS.Depth      = cShelly.depth;
    cS.t          = datetime(cShelly.YYYY, ...
        cShelly.MM, ...
        cShelly.dd, ...
        cShelly.hh, ...
        cShelly.mm, ...
        cShelly.ss);
    %%
    
    % load the regional catalog to get background seismicity
    cRegional       = readtable('Ridgecrest_ComCat.csv');
    cR = table;
    cR.Mag        = cRegional.mag;
    cR.Lat        = cRegional.latitude;
    cR.Long       = cRegional.longitude;
    cR.Depth      = cRegional.depth;
    cR.t          = datetime(cRegional.time,'InputFormat','yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
    %%
    % parse time formats e.e
    shelly_min_time = cS.t(cS.Mag == 6.4); %  min(cS.t);
    
    % make combined catalog:
    c = [cR(cR.t<shelly_min_time,:); cS(cS.t>=shelly_min_time,:)];
end

end

function [cat_Reg,catS_fs,ms_fs,catS_ms,ms_ms] = build_catalog(c,Mfs,mc0,width, ...
                                            strike_foreshock,dip_foreshock, ...
                                            strike_mainshock,dip_mainshock)

c.Mag   = round(c.Mag*10)/10; % make the catalog uniform by apply consistent rounding
t       = c.t;
% very preliminary max curvature completeness filter through the catalog to
% remove events that wont be considered in the analysis, depressingly this
% matters

c       = c(c.Mag>=mc0,:); t=t(c.Mag>=mc0);

switch length(width) 
    case 1
        width = repmat(width,1,2);
    case 2
        % good
    otherwise
        error('width must be a single value or a pair to describe the foreshock and the mainshock');
end

%% Foreshock: 
% (querried simply based on the magnitude - this could fail if
% there are other large earthquakes of the exact same magnitude in the
% catalog)

tfs     = t(find(c.Mag==Mfs,1,'first')); % assumes that the fs of mag Mfs is the first in the catalog
FSbuffer= width(1);                            % (km) this is the width of the 'box' for which bvalues will be conisdered

Ifs = t==tfs;                  
FS  = c(Ifs,:);

[I,~,~] = in_box(c.Lat, c.Long, c.Depth,...         % Catalog
                 FS.Lat,FS.Long,FS.Depth,FS.Mag,... % Box center, mag -> length
                 strike_foreshock,dip_foreshock,... % Strike Dip (gcmt) 
                 FSbuffer,...                       % Width of the box
                 false,'', ...                      % Save catalog? / file name
                 c.Mag,c.t);                        % Event magnitude and time     
catFS   = c(I,:);

%% Mainshock:
% (querried based on being the largest event in the catalog)
tms     = t(c.Mag ==max(c.Mag)); 
MSbuffer  = width(2);                          % (km) this is the width of the 'box' for which bvalues will be conisdered

% index for the mainshock
Ims = t==tms;
MS  = c(Ims,:);

[I,~,~] = in_box(c.Lat, c.Long, c.Depth,...         % Catalog
                 MS.Lat,MS.Long,MS.Depth,MS.Mag,... % Box center, mag -> length
                 strike_mainshock,dip_mainshock,...% Strike Dip (gcmt)
                 MSbuffer,...                       % Width of the box
                 false,'', ...                      % Save catalog? / file name
                 c.Mag,c.t);                        % Event magnitude and time            
catMS        = c(I,:);


%% save background seismicity

catREG  = c(c.t<tfs,:);
[cat_Reg,catS_fs,ms_fs,catS_ms,ms_ms] = c2c(catREG,catFS,FS,catMS,MS);

% At this point there are two catalogs, one with centered on the foreshock
% and another centered on the mainshock. As shown below:

% %% 
% 
% figure; 
% subplot(1,2,1); hold on
% plt_eq = @(C) scatter(C.Long,C.Lat,(C.Mag+1).^2,'filled','MarkerFaceAlpha',0.8);
% plt_eq(catFS);
% plt_eq(catMS);
% plt_eq(catREG);
% axis equal
% 
% subplot(1,2,2)
% hold on
% plt_tms = @(C) scatter(C.t, C.Mag, ...
%                         (C.Mag+1).^3,...
%                        'filled','MarkerFaceAlpha',0.5);
% plt_tms(catFS);
% plt_tms(catMS);
% plt_tms(catREG);
% 
% 
% legend('Regional Catalog','Bkg and fs','Mainshock')

    function varargout = c2c(varargin)
        
        for n = 1:length(varargin)
            C = varargin{n};
            T = decyear(C.t);
            NN= nan(size(T));
            varargout{n} = [C.Long,C.Lat,T,NN,NN,C.Mag,C.Depth];
        end
        
    end

end

function [t,b,brel] = partial_time_series(Tms,Tms2,days,days_post2,cat_Reg,ms,Tmin,Tmax,catS, corr,ExpertChoiceMc)

% ExpertChoiceMc is 3 by 1 and defines the first pass completeness threshold for the background, foreshock and mainshock time series 
% if any of these are set to NaN a Max curvature threshold is calculated
% with the corresponding correciton factor


% define the correction to be applied to the Maximum Curvature Method
% following (Wiemer and Woessner, 2005). We allow to apply different pre-
% and post mainshock corrections but the defaults is equal = 0.2 
corr_post =corr;
corr_pre  =corr;

%Magnitude binning
mbin    =0.1;

% Window lenght for the time-series: Npre, before the M>=6 event, Npost
% after  (due to the event abundance, we can use larger sample sizes during
% the rich aftershock sequence to reduce uncertainties. Note these sample
% sizes are before cutting at the subsequent define completeness levels. 
Npre    = 250;
Npost   = 400;

% in the case the subcatalog does not contain Npre events, a new subcatalog is created selecting the closest Nreg events to the hypocenter
Nreg    = 250;

% Minimum number of event above the magnitude of completeness to estimate a
% the b-value. This is minimum that applies after cutting the sample size
% Npre or Npost at the determinej Mc. 
% Nmin    = 50; % Why put this here? This gives the impression that this number is not important - KDC 


% Define Latitude, Longitude, Magnitude, Depth and Time of the event
LATms=ms(1,2);
LONms=ms(1,1);
Mms=ms(1,6);
% Monthms=ms(1,4);
% Dayms=ms(1,5);
% Depthms=ms(1,7);

% Some housekeeping parts and preparatory work
% 
% sorted catalog by time. 
catS=sortrows(catS,3);

% cut the catalog at Tmin to not include in the calculation of the background level:
% 1. in the case of Amatrice and Norcia, the aftershocks of L'Aquila (M6.3, 2009)
% 2. in the case of Kumamoto, the first months of the Tohoku aftershocks
ll=catS(:,3)>=Tmin;
catS=catS(ll,:);

% querry magnitude range 
Mrange=min(catS(:,6)):mbin:max(catS(:,6));

% The catalog is then divided in 3 sub-catalogs: background (catS_pre), in between (catS_post) and after the second M>=6 event (catS_post2)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ll=catS(:,3)<Tms; %last event before the first M>=6 event % kdc not necessary if done carefully
catS_pre=catS(ll,:);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% %remove the first X dayfs after the mainshocks, Expert Choice (# defined above)
hh=catS(:,3)>Tms+days/365;
catS_post=catS(hh,:);
catS_post1=catS_post;   
% catS_post(1,6) % kdc

hh=catS_post(:,3)<Tms2; %%last event before the second M>=6 event % kdc not necessary if done carefully
catS_post=catS_post(hh,:);
% catS_post(1,6) % kdc


% Define a raw magnitude of completeness (Mc_bulk) to pre-cut the catalog: this allow the Maximum Curvature to perform better.
% For the magnitude of completeness, conservative choices are always adopted
% calls function Mc_bulk2

if strcmp(ExpertChoiceMc.pre,'none')
    [Mc_pre,cntnumb_pre]=Mc_bulk2(catS_pre, Mrange,corr_post); %kdc 
else
    Mc_pre = ExpertChoiceMc.pre;
    warning('Background catalog disregards Mc calculation and used expert choice instead')
end
catSpre_orig=catS_pre;
Mcpre_orig=Mc_pre;

% The same for the post period 
cat_test=catS_post;

% kdc: turn this in an explicit decision
if strcmp(ExpertChoiceMc.post,'none')
    [Mc_post,cntnumb_post]=Mc_bulk2(catS_post, Mrange,corr_post); % kdc
else
    Mc_post = ExpertChoiceMc.post;
    warning('Foreshock catalog disregards Mc calculation and used expert choice instead')
end
Mcpost_orig = Mc_post;

% do the cutting
ll=catS_pre(:,6)>=Mc_pre; % kdc see below:
% ll=catS_pre(:,6)>=Mc_pre-corr_pre; % kdc ERROR? Why is this ok?
catS_pre=catS_pre(ll,:);
catS_pre_orig=catS_pre;

%ll=catS_post(:,6)>=1.5; 
ll=catS_post(:,6)>= Mcpost_orig;
catS_post=catS_post(ll,:);
catS_post_orig=catS_post;


% Step 1; Estimate the reference b-value
if length(catS_pre(:,1))>= Npre  % Do the analysis if we have enough events 
    % background reference b-value estimation: the median of all the bpre estimations
    [prpre,Mcpre, bpre, apre, tpre,bprevalue,timewindowpre,result_flag_pre,bpreplus,bpreminus]...
        =abwithtime_pre(catS_pre,Npre,mbin,Mms,corr_pre);
 
    
else % Not enough events, default to regional 
    % in such case (here for the Kumamoto foreshock M6.5), since we cannot estimate a b-value using the events
    % inside the box, we upload a reduced version of the JMA catalog, to calculate a regional bvalue as the reference one
    
    cat_Reg         = cat_Reg(cat_Reg(:,3)>Tmin & cat_Reg(:,3)<Tms, :); % kdc - seems dangerous and ensure that the Tmin is not set reduntantly
    dists2d_Npre    = deg2km(distance(LATms,LONms,cat_Reg(:,2),cat_Reg(:,1)));
    [dists_sort,is] = sort(dists2d_Npre);
    asort_Npre      = cat_Reg(is,:);
    if length(cat_Reg(:,1))>=Nreg
        cat_Reg         =asort_Npre(1:Nreg,:);
        Rreg            =dists_sort(Nreg,:);
    end
    cat_Reg     = sortrows(cat_Reg,3);
    sizecat     = size(cat_Reg);  
    [Mcpre_orig, bpre, apre,bprevalue,catSpre_orig]=breg_NLI(cat_Reg,mbin,Tms,Mms,corr_pre);   
end

% Define the reference b-value 
breference=round(nanmean(bpre),1);

% b-value time series following the first M>=6 event

% call the function abwithtime for the post- event 1 sequence data that will compute the output time series. 
[prpost,Mcpost,bpost,apost,tpost,bpostvalue,timewindow,result_flag_post, ...
    bpostplus,bpostminus]=abwithtime_post(catS_post,Npost,mbin,Mms,corr_post);

hh=catS(:,3)>Tms2+days_post2/365;
catS_post2=catS(hh,:);

% kdc explicit about Mc choice 
if strcmp(ExpertChoiceMc.post2,'none')
    [Mc_post2,cntnumb_post2]=Mc_bulk2(catS_post2, Mrange,corr_post); % kdc
else
    Mc_post2=ExpertChoiceMc.post2; % to reproduce Laura's results for Ridgecrest % kdc
    warning('Aftershock catalog disregards Mc calculation and used expert choice instead')
end
Mcpost_orig2 = Mc_post2;

%ll=catS_post2(:,6)>=1.8; % kdc - This seems inconsistent with description in methods
ll=catS_post2(:,6)>=Mcpost_orig2; % kdc
catS_post2=catS_post2(ll,:);
catS_post_orig2=catS_post2;

% b-value time series following the second M>=6 eve
% call the function abwithtime for the post- event 2 sequence data that will compute the output time series. 

[prpost2,Mcpost2,bpost2,apost2,tpost2,bpostvalue2,timewindow2,result_flag_post2, ...
    bpostplus2,bpostminus2]=abwithtime_post(catS_post2,Npost,mbin,Mms,corr_post);

[bpostmax2,ind]=max(bpost2);
tpostmax2=tpost2(ind);
magcopostmax2=Mcpost2(ind);
apostmax2=apost2(ind);


%% kdc - this is really all that is needed to build the time series
b = [bpostplus',nan,bpostplus2'; ...
     bpost',nan,bpost2'; ...
     bpostminus',nan,bpostminus2'];
 
 brel = b/breference;
 
 t = [tpost',nan,tpost2'];

 

end

