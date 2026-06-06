% Copyright: Mohan Parthasarathy 2026
% startup.m for PINNLab
% Run this file or open MATLAB in the repository root before launching PINNLab.
% It adds the repository and all subfolders to the MATLAB path.

repoRoot = fileparts(mfilename('fullpath'));
addpath(genpath(repoRoot));
fprintf('PINNLab path initialized: %s\n', repoRoot);
fprintf('Launch the dashboard with: PINNLab_Dashboard\n');
