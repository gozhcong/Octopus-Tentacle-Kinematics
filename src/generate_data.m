%% GENERATE_DATA.M
% Generates synthetic octopus tentacle centerline data for POD analysis.
%
% OUTPUT
%   octopus_tentacle_data.csv  saved to ../data/
%
% COLUMNS
%   frame  – integer frame index (0-indexed, matches Python convention)
%   phase  – 'extension' | 'grasping' | 'retraction'
%   time   – time in seconds (50 Hz capture rate)
%   s      – arc-length coordinate along tentacle (m), s in [0, 0.15]
%   x,y,z  – 3-D centerline position in metres
%
% PHYSICAL DESIGN
%   L  = 0.15 m  (15 cm, realistic for Octopus vulgaris)
%   Ns = 20      spatial stations along arc length
%   dt = 0.02 s  (50 Hz)
%   M  = 100     total frames  (40 ext + 25 grasp + 35 retract)
%
% FREQUENCY CONTENT (verified by phase-windowed FFT after POD)
%   Extension  : f* ~ 1.2 Hz   (slow proximo-distal bending wave)
%   Grasping   : f* ~ 10-14 Hz (high-freq sucker-contact oscillations)
%   Retraction : f* ~ 4.3 Hz   (decaying structural rebound)
%
% USAGE
%   >> generate_data          % saves CSV to ../data/
%   >> generate_data('.')     % saves CSV to current folder

function generate_data(out_dir)

if nargin < 1
    out_dir = fullfile(fileparts(mfilename('fullpath')), '..', 'data');
end

% Ensure output directory exists
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

%% Parameters
L      = 0.15;           % tentacle length (m)
Ns     = 20;             % spatial stations
dt     = 0.02;           % time step (s)  ->  50 Hz
N_ext  = 40;             % extension frames
N_grp  = 25;             % grasping frames
N_ret  = 35;             % retraction frames
prey   = [0.13, 0.025, 0.01];   % prey position (m)

rng(42);                 % fixed seed for reproducibility

s_vec  = linspace(0, L, Ns)';
noise  = 1.5e-4;         % position noise std (m)

%% Pre-allocate output table columns
n_rows  = (N_ext + N_grp + N_ret) * Ns;
T_frame = zeros(n_rows, 1);
T_phase = strings(n_rows, 1);
T_time  = zeros(n_rows, 1);
T_s     = zeros(n_rows, 1);
T_x     = zeros(n_rows, 1);
T_y     = zeros(n_rows, 1);
T_z     = zeros(n_rows, 1);
row     = 1;

%% ── PHASE 1: EXTENSION (frames 0–39) ────────────────────────────────────
% Smooth proximo-distal elongation wave toward prey.
% Bending wave: f = 1.5 Hz, amp = 0.018*s/L (m) — 12% of L at tip.
for fi = 0:(N_ext-1)
    t  = fi * dt;
    al = fi / (N_ext - 1);          % progress 0 → 1

    for si = 1:Ns
        sv = s_vec(si);
        n  = sv / L;

        % Rest pose
        xr = sv * 0.55;
        yr = -0.03 * n^2;
        zr = 0.0;

        % Extended target
        x_tgt = prey(1) * n * (0.85 + 0.15*n);
        y_tgt = prey(2) * n * (1 - (1-n)^2);
        z_tgt = prey(3) * n * sin(pi*n) * 0.5;

        % Proximo-distal wave progress
        wp = max(0, min(1, al - 0.25*n));

        x = xr + wp*(x_tgt - xr);
        y = yr + wp*(y_tgt - yr);
        z = zr + wp*(z_tgt - zr);

        % Transverse bending wave
        ab = 0.018 * n;
        y  = y + ab * sin(2*pi*1.5*t - pi*n);
        z  = z + ab * 0.5 * cos(2*pi*1.5*t - pi*n*0.7);

        % Sensor noise
        x = x + noise * randn();
        y = y + noise * randn();
        z = z + noise * randn();

        T_frame(row) = fi;
        T_phase(row) = "extension";
        T_time(row)  = round(t,    4);
        T_s(row)     = round(sv,   5);
        T_x(row)     = round(x,    6);
        T_y(row)     = round(y,    6);
        T_z(row)     = round(z,    6);
        row = row + 1;
    end
end

%% ── PHASE 2: GRASPING (frames 40–64) ────────────────────────────────────
% Distal 60% executes curl wrap around prey.
% Oscillation: 10 Hz and 14 Hz, amp = 0.020*curl_zone (m) at tip.
grasp_final_x = zeros(Ns, 1);
grasp_final_y = zeros(Ns, 1);
grasp_final_z = zeros(Ns, 1);

for fi = 0:(N_grp-1)
    t   = (N_ext + fi) * dt;
    al  = fi / (N_grp - 1);
    fG  = N_ext + fi;
    t_loc = fi * dt;

    for si = 1:Ns
        sv = s_vec(si);
        n  = sv / L;

        % Fully extended baseline
        xf = prey(1) * n * (0.85 + 0.15*n);
        yf = prey(2) * n * (1 - (1-n)^2);
        zf = prey(3) * n * sin(pi*n) * 0.5;

        % Distal curl zone
        cz = max(0.0, (n - 0.4) / 0.6);
        ca = al * pi * 1.4 * cz;

        x = xf - 0.030 * cz * sin(ca) * al;
        y = yf - 0.025 * cz * (1 - cos(ca)) * al;
        z = zf + 0.015 * cz * sin(ca * 0.9) * al;

        % Grasping oscillations
        ag = 0.020 * cz;
        x  = x + ag * sin(2*pi*10.0 * t_loc);
        y  = y + ag * 0.9 * cos(2*pi*14.0 * t_loc);
        z  = z + ag * 0.6 * sin(2*pi*10.0 * t_loc + pi/3);

        x = x + noise * randn();
        y = y + noise * randn();
        z = z + noise * randn();

        if fi == N_grp - 1
            grasp_final_x(si) = x;
            grasp_final_y(si) = y;
            grasp_final_z(si) = z;
        end

        T_frame(row) = fG;
        T_phase(row) = "grasping";
        T_time(row)  = round(t,    4);
        T_s(row)     = round(sv,   5);
        T_x(row)     = round(x,    6);
        T_y(row)     = round(y,    6);
        T_z(row)     = round(z,    6);
        row = row + 1;
    end
end

%% ── PHASE 3: RETRACTION (frames 65–99) ──────────────────────────────────
% Base-to-tip retraction wave back to rest.
% Structural rebound: 4 Hz, decaying exponentially, amp = 0.018*s/L (m).
for fi = 0:(N_ret-1)
    t   = (N_ext + N_grp + fi) * dt;
    al  = fi / (N_ret - 1);
    fG  = N_ext + N_grp + fi;
    t_loc = fi * dt;

    for si = 1:Ns
        sv = s_vec(si);
        n  = sv / L;

        % Rest pose
        xr = sv * 0.55;
        yr = -0.03 * n^2;
        zr = 0.0;

        % Start from final grasping configuration
        xs = grasp_final_x(si);
        ys = grasp_final_y(si);
        zs = grasp_final_z(si);

        % Retraction wave (tip retracts last)
        wp = min(1, max(0, al + 0.2*n));
        x  = xs + wp*(xr - xs);
        y  = ys + wp*(yr - ys);
        z  = zs + wp*(zr - zs);

        % Decaying structural rebound
        decay = exp(-2.0 * al);
        ar    = 0.018 * n * decay;
        x     = x + ar * sin(2*pi*4.0 * t_loc);
        y     = y + ar * 0.8 * cos(2*pi*3.5 * t_loc);
        z     = z + ar * 0.5 * sin(2*pi*5.2 * t_loc);

        x = x + noise * randn();
        y = y + noise * randn();
        z = z + noise * randn();

        T_frame(row) = fG;
        T_phase(row) = "retraction";
        T_time(row)  = round(t,    4);
        T_s(row)     = round(sv,   5);
        T_x(row)     = round(x,    6);
        T_y(row)     = round(y,    6);
        T_z(row)     = round(z,    6);
        row = row + 1;
    end
end

%% Save
out_path = fullfile(out_dir, 'octopus_tentacle_data.csv');
T = table(T_frame, T_phase, T_time, T_s, T_x, T_y, T_z, ...
          'VariableNames', {'frame','phase','time','s','x','y','z'});
writetable(T, out_path);
fprintf('Saved %d rows to: %s\n', height(T), out_path);
fprintf('Frames: %d  |  Spatial stations: %d  |  Duration: %.2f s\n', ...
        N_ext+N_grp+N_ret, Ns, (N_ext+N_grp+N_ret-1)*dt);
end
