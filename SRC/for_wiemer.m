% Here we test the range of outcome that can be produced from using foreshock the
% traffic light system. Particularly, we test how the outcomes are
% sensitive to uniform priors for:
% 
% - catalog start date
% - fault orientation
% - Mc correction
% 
% These are all allowable within the criteria presented in Gulia and
% Wiemer, 2019. Thes pa


%% example time series for Ridgecrest
% I think it is informative to play around with these inputs. Figure 4 in
% our paper showed a monte carlos sampling of  time series samples uniform priors
% for the background catalog start date (2000–2012), foreshock source
% volume choice (choosing one or the other of the two orthogonal planes
% ruptured in the foreshock), Mc maximum curvature correction (0.1–0.3),
% and blind times after the foreshock (0.01–0.5 days) and mainshock (0.5–5)
% days. The resulting time series are very different if, say, a different
% catalog start date is selected.

mc_correction = 0.20;
catalog_start_date = 2000;
strike_dip    = [227, 86];
foreshock_blind_time = 0.05;
mainshock_blind_time = 2;
line_opt = {'Color',[0 0 0],'LineWidth',2};

plot_gw_timeseries('Earthquake','Ridgecrest', ...
                          'fsM',                    6.4, ...
                          'msM',                    7.1, ...
                          'MaxCurvatureCorrection', mc_correction, ...
                          'CatalogStartDate',       catalog_start_date, ...
                          'ForeshockStrike',        strike_dip(1), ...
                          'ForeshockDip',           strike_dip(2), ...
                          'MainshockStrike',        321, ...
                          'MainshockDip',           81, ...
                          'ForeshockBlindTime',     foreshock_blind_time, ...
                          'MainshockBlindTime',     mainshock_blind_time, ...
                          'PLotOptions',            line_opt, ...
                          'NewFigure',              true, ...
                          'PlotOutput',             true);
                    
                      
%% plot the verion prefered solution by gulia  
mc_correction = 0.20;
catalog_start_date = 2010;
foreshock_blind_time = 0.05;
mainshock_blind_time = 1;
line_opt = {'Color',[0 0 0],'LineWidth',2};
expertChoiceMc.pre = 'none';
strike_dip    = [137, 87];
expertChoiceMc.post= 1.5; % this is specific to this code (i.e. the option to make a decision to set the first pass Mc)
expertChoiceMc.post2=1.5; 

plot_gw_timeseries('Earthquake','Ridgecrest', ...
                          'fsM',                    6.4, ...
                          'msM',                    7.1, ...
                          'MaxCurvatureCorrection', mc_correction, ...
                          'CatalogStartDate',       catalog_start_date, ...
                          'ForeshockStrike',        strike_dip(1), ...
                          'ForeshockDip',           strike_dip(2), ...
                          'MainshockStrike',        321, ...
                          'MainshockDip',           81, ...
                          'ForeshockBlindTime',     foreshock_blind_time, ...
                          'MainshockBlindTime',     mainshock_blind_time, ...
                          'McExpertChoice',         expertChoiceMc, ...
                          'PLotOptions',            line_opt, ...
                          'NewFigure',              false);

                   
