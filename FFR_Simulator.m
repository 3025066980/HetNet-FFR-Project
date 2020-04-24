%**************************************************************************
% Filename: FFR_Simulator.m
% Group Name: GTW-E
% Date: 03/17/2020
% Description: Script used to simulate Fractional Frequency Reuse(FFR)
% medthods for HetNet applications. FFR algorithm is modeled to
% analyze performance tradeoffs. 
%
% FFR Algorithms:
%                FFR-3SL (Proposed Paper) 
%
%**************************************************************************

%----------------------------------------------------
% Common Sim Variables
%----------------------------------------------------
BER     = 10^-5;                % Target Bit Error Rate(BER)
alpha   = -1.5/log(BER);        % Constant for target BER
delta_f  = 15e3;                % Subcarrier spacing (Hz)
CH_BW   = 20e6;                 % Channel Bandwidth (Hz)
Max_Subcarriers = CH_BW/delta_f;% Maximum number of subcarriers
macro_radius = 500;             % Macrocell radius(m)
femto_radius = 30;              % femtocell radius(m)
m_users = 150;                  % Macrocell Users
f_users = 150;                  % Femtocell Users
SCpRB   = 12;                   % Sub-carriers per resource block
Num_RB  = 100;                  % Total number of resource blocks
Num_SC  = Num_RB*SCpRB;         % Number of subcarriers
transmitPower_macro = 20;       % Macrocell transmit power in Watts
MC_TxP_vec  = [10 15 20];       % Macrocell Base Station Transmit Power
transmitPower_femto = 20e-3;	% Femtocell Base Station Transmit Power in Watts
transmitPower_mue   = 1;        % MUE transmit power (ASSUMPTION because the paper doesn't cite one)
Noise_PSD  = -174;              % Noise Power Spectral Density (dBm/Hz)
Num_Mc  = 7;                    % Number of Macrocells
Num_Fc  = 30;                   % Number of Femtocells per macrocell
T_Num_Fc  = 210;                % Total Number of Femtocells
Num_RB  = 100;                  % Number of Resource Blocks
SB_Sect = 4;                    % Subbands per sector
total_subbands = 7;             % Total freq band is divided into 7 subbands A-G
d_vec  = 5;                     % Distance from base station to user in meters
MUE_vec = 1:150;                % vector of macro user equipments to loop through
subcarriers_vec = 1:1333;       % vector of subcarriers. This was calculated by 
                                % dividing the channel bandwidth of 20 MHz by the 
                                % subcarrier spacing of 15 kHz. 
number_of_runs = 100;           % number of times to run the Monte Carlo sim


%-------------------------------------------
% Macrocell - SINR, Capacity, and Throughput
%-------------------------------------------
% Precompute femtocell distance vector for simulation
% Distance to any interferring femtocell will be 60 - 470m
d_femto_vec = round(rand(1,Num_Fc)*(470) + (2*femto_radius));   

% Precompute femtocell distance vector for simulation
d_user_vec  = round(rand(1,m_users)*(macro_radius)+1);

idx=0;
SubCarriers_Assigned = 0;
Nf_vec = 30:210;
Tm_macro_vec = zeros(1,length(Nf_vec));
for Nf=Nf_vec
    
    SubCarriers_Assigned = 0;
    Tm_user_vec = zeros(1,m_users);
    for m=1:m_users
        
        % Convert Macrocell power to watts
        MC_TxP = MC_TxP_vec(3);
        MC_TxP_W = 10^(MC_TxP/10);
        
        % Convert Femtocell power to watts
        FC_TxP_W = 10^(transmitPower_femto/10);
        
        
        % Summation of M neighboring Macro-cell's Power & Gain products on sub-carrier k
        % Equation 4 - Denomonator middle summation
        sigma_PMp_GMp = 0; % Initialize to zero
        sigma_PF_GF   = 0; % Initialize to zero
        for mc=1:(Num_Mc-1)
            %d = d_vec(m);
            d=866;
            PL_macro = 28.0 + 35*log10(d);
            Gain = 10^-(PL_macro/10);
            sigma_PMp_GMp = sigma_PMp_GMp + (MC_TxP_W*Gain);
            
            % Summation of F neighboring Femto-cell Power & Gain products on sub-carrier k
            for f=1:(Num_Fc)
                PL_femto = 28.0 + 35*log10(d_femto_vec(f));
                Gain = 10^-(PL_femto/10);
                sigma_PF_GF = sigma_PF_GF + (FC_TxP_W*Gain);
            end
            
        end
        
        % Calculate channel gain (NOTE: Removing the Xsigma and the |H|
        % Rayleigh Gaussian distribution).
        PL_user = 28.0 + 35*log10(d_user_vec(m));
        Ch_Gain_W = 10^(-PL_user/10);
        
        % SINR equation for a given Macro-cell on sub-carrier k
        % NOTE: this is equation 4 from the paper
        SINRmk = (MC_TxP_W*Ch_Gain_W)/(10^((Noise_PSD*delta_f)/10) + sigma_PMp_GMp + sigma_PF_GF);
        
        % Capacity of macro user m on sub-carrier k
        Cmk = delta_f*log2(1+alpha*SINRmk);
        

        % Calculate Throughput of the Macro-cell across all m users and all
        % subcarriers available to user.
        Tm = 0; % Initialize to zero
        for k=1:SCpRB
            
            % Create subcarrier assignments, but only assign up to the
            % alotted maximum number based on bandwidth and channel spacing
            if SubCarriers_Assigned <= Max_Subcarriers
                Beta_km = 1;
                SubCarriers_Assigned = SubCarriers_Assigned + 1;
            else
                Beta_km = 0;
            end
        
            Tm = Tm + Cmk * Beta_km;
        end
        
        % Assign throughput based on macrouser
        Tm_user_vec(m) = Tm;
        
    end
    
    idx = idx+1;
    Tm_macro_vec(idx) = sum(Tm_user_vec);
    
end

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% vvv Teresa's Additions vvv

% for ONE MUE in macrocell A, calculate the throughput
% assume MUE is assigned to 8 subcarriers

% 1x30 array for holding all throughput values - intialize all to 0
throughput_macro_array = zeros(1,210);
femto_distances = zeros(1,210);
mue_distances   = zeros(1,1050);
femtocell_array = 1:210;

% increment total femtocells for graphing
% Only include femtocells within macrocell A
for total_femto_count = femtocell_array

    % hold the sum of all MUE throughput - reset at every femtocell
    % increment
    total_throughput = 0;
    
    % multiply noise spectral density by the subcarrier spacing and convert
    % to Watts
    denominator = 10^((Noise_PSD * delta_f)/10);

    % calculate macrocell interference
    % Summation of M neighboring Macro-cell's Power & Gain products on sub-carrier k
    sigma_Pkm_GkmM = 0; % Initialize to zero
    % loop from 1 to total macrocells-1 because we aren't counting the cell
    % we are in
    for m=1:(Num_Mc-1)
        % assuming macrocell A, all other towers are 866 m away
        d_macro = 866;
        % outdoor pathloss - equation (2) from paper
        PL_macro = 28.0 + 35*log10(d_macro);

        % equation (3) from paper
        CG_macro = 10^-(PL_macro/10);

        % Add up all the interferers
        sigma_Pkm_GkmM = sigma_Pkm_GkmM + (transmitPower_macro*CG_macro);
    end

    % add the macrocell interferers to the denom 
    denominator = denominator + sigma_Pkm_GkmM;

    % femtocell interference
    % Summation of F neighboring Femto-cell Power & Gain products on sub-carrier k
    sigma_PkF_GkmF = 0; % Initialize to zero

    % Only include femtocells within macrocell A
    % TODO: how to calculate distances to femtocells in neighboring macrocells
    for f=1:total_femto_count
           
        % if this femto distance hasn't been populated yet, populate it
        if femto_distances(f) == 0
            % choose a random distance within this macrocell
        % TODO: create an array from 1-30 within each macrocell of random,
        % non-repeating distances?
        % randomize femtocell radius for entirety of network radius
            femto_distances(f) = randi([1, 1299]);
        end
        
        d_femto = femto_distances(f);
        
        PL_femto = 28.0 + 35*log10(d_femto);
        CG_femto = 10^-(PL_femto/10);
        sigma_PkF_GkmF = sigma_PkF_GkmF + (transmitPower_femto*CG_femto);
    end

    % add the macrocell interferers to the denom 
    denominator = denominator + sigma_PkF_GkmF;
    
    % Loop through all MUEs in the network
    for mue = 1:1050
        
        % if this femto distance hasn't been populated yet, populate it
        if mue_distances(mue) == 0
            % choose a random distance within the entire network
            mue_distances(mue) = randi([1, 1299]);
        end
        
        d_mue = mue_distances(mue);
       
        % Calculate for ONE subcarrier
        % assign the MUE to subcarriers (a 2D array of Beta?)
        % calculate the PL of the MUE based on that distance
        PL_mue = 28.0 + 35*log10(d_mue);

        % calculate channel gain for MUE
        CG_mue = 10^-(PL_mue/10);

        % numerator of the SINR equation
        % **NOTE From Eric: I read throught the paper and the references and this
        % power needs to be the macrocell transmit power. 
        numerator = transmitPower_macro * CG_mue;

        % combine values into SINR
        SINR_km = numerator / denominator;

        % calculate channel capacity
        channelCapacity_macro = delta_f * log2(1 + (alpha * SINR_km));

        % multiply beta and the channel capacity
        % each MUE is assigned to 8 subcarriers, so multiply channel capacity by 8
        % (because 8 of the Beta values will be 1 and we are summing over all
        % subcarriers)
        throughput_macro = channelCapacity_macro * 8;
        
        total_throughput = total_throughput + throughput_macro;
    end
        
    % assign the throughput for this femtocell increment to the array
    throughput_macro_array(total_femto_count) = total_throughput;
end

figure; 
plot(femtocell_array,throughput_macro_array, 'o');
xlabel('Number of Femtocells');
ylabel('Throughput (bps)');
title('Teresa plot');

% ^^^ Teresa's Additions ^^^
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%-------------------------------------------
% Femtocell - SINR, Capacity, and Throughput
%-------------------------------------------










%**************************************************************************
% Figures/Plots
%**************************************************************************

figure; 
plot(Nf_vec,(Tm_macro_vec/1e6), 'o');
xlabel('Number of Femto-cells');
ylabel('Throughput (Mbps)');
title('Cool plot');
