%**************************************************************************
% Filename: FFR_Simulator.m
% Group Name: GTW-E
% Date: 03/17/2020
% Description: Script used to simulate Fractional Frequency Reuse(FFR)
% medthods for HetNet applications. Four FFR algorithms are modeled to
% analyze performance tradeoffs between algorithm approaches. 
%
% FFR Algorithms:
%                FFR-3SL (Proposed Paper) 
%                FFR-3  (Reference:10) 
%                OSFFR  (Reference:11)
%                FFR-3R (Reference:12) 
%
%**************************************************************************

%----------------------------------------------------
% Common Sim Variables
%----------------------------------------------------
BER     = 10^-6;         % Target Bit Error Rate(BER)
alpha   = -1.5/log(BER); % Constant for target BER
deltaf  = 15e3;          % Subcarrier spacing (Hz)
CH_BW   = 20e6;          % Channel Bandwidth (Hz)
Mc_rad  = 500;           % Macrocell radius(m)
m_users = 150;           % Macrocell Users
f_users = 150;           % Femtocell Users
SCpRB   = 12;            % Sub-carriers per resource block
Num_RB  = 100;           % Total number of resource blocks
Num_SC  = Num_RB*SCpRB;  % Number of subcarriers
MC_TxP  = [10 15 20];    % Macrocell Base Station Transmit Power
FC_TxP  = 20e-3;         % Femtocell Base Station Transmit Power
No_PSD  = -174;          % Noise Power Spectral Density (dBm/Hz)
Num_Mc  = 7;             % Number of Macrocells
Num_Fc  = 30;            % Number of Femtocells per macrocell
T_Num_Fc  = 210;         % Total Number of Femtocells
Num_RB  = 100;           % Number of Resource Blocks
SB_Sect = 4;             % Subbands per sector
d_vec  = 5;              % Distance from base station to user in meters
Lwalls = [7 10 15];      % Loss through walls [light internal, internal, external]
wall_type = 1;           % Selects wall type from array of wall loss vector
                         % hard coded to 1(light internal) for now, will 
                         % implement selector code later.

%**************************************************************************
% FFR-3SL Code (Proposed Paper)
%**************************************************************************

%-------------------------------------------
% Macrocell - SINR, Capacity, and Throughput
%-------------------------------------------
idx=0;
Tm_vec = [];
Nf_vec = 30:210;
for Nf=Nf_vec
    
    Num_Mc = 7;
    Num_Fc = Nf;
    
    % Convert Macrocell power to watts
    MC_TxP = MC_TxP(1);
    MC_TxP_W = 10^(MC_TxP/10);
    
    % Convert Femtocell power to watts
    FC_TxP_W = 10^(FC_TxP/10);
    
    
    % d_vec = [
    %     866  %B->A
    %     866  %B->C
    %     1500 %B->D
    %     1732 %B->E
    %     1500 %B->F
    %     866  %B->G
    %     ];
    
    % Summation of M neighboring Macro-cell's Power & Gain products on sub-carrier k
    sigma_PMp_GMp = 0; % Initialize to zero
    for m=1:(Num_Mc-1)
        %d = d_vec(m);
        d=866;
        PL_outdoor = 28.0 + 35*log10(d);
        PL = PL_outdoor;
        Gain = 10^-(PL/10);
        sigma_PMp_GMp = sigma_PMp_GMp + (MC_TxP_W*Gain);
    end
    
    % Summation of F neighboring Femto-cell Power & Gain products on sub-carrier k
    sigma_PF_GF = 0; % Initialize to zero
    for f=1:(Num_Fc)
        %d = round(rand*(2*Mc_rad));
        d = 500;
        PL_outdoor = 28.0 + 35*log10(d);
        PL = PL_outdoor;
        Gain = 10^-(PL/10);
        sigma_PF_GF = sigma_PF_GF + (FC_TxP_W*Gain);
    end
    
    
    Ch_Gain_W = 10^(28/10);
    % SINR equation for a given Macro-cell on sub-carrier k
    SINRmk = (MC_TxP_W*Ch_Gain_W)/(10^((No_PSD*deltaf)/10) + sigma_PMp_GMp + sigma_PF_GF);
    
    % Capacity of macro user m on sub-carrier k
    Cmk = deltaf*log2(1+alpha*SINRmk);
    
    % Calculate Throughput of the Macro-cell across all m users
    Tm = 0; % Initialize to zero
    for m=1:m_users
        Beta_km = round(rand);
        Beta_km = 1; 
        Tm = Tm + Cmk * Beta_km;
    end
    
    idx = idx+1;
    Tm_vec(idx) = Tm;
    
end
    

%-------------------------------------------
% Femtocell - SINR, Capacity, and Throughput
%-------------------------------------------





%**************************************************************************
% FFR-3 Code FFR-3  (Reference:10)
%**************************************************************************




%**************************************************************************
% OSFFR Code (Reference:11)
%**************************************************************************








%**************************************************************************
% FFR-3R Code FFR-3R (Reference:12)
%**************************************************************************







%**************************************************************************
% Figures/Plots
%**************************************************************************

figure; 
plot(Nf_vec,Tm_vec, 'o');
xlabel('Number of Femto-cells');
ylabel('Throughput (bps)');
