%% OCTOPUS_POD_ANALYSIS.M
% Data-driven spectral decomposition of octopus tentacle kinematics.
%
% Implements snapshot Proper Orthogonal Decomposition (POD) combined with
% phase-windowed spectral analysis to characterise the reach-grasp-retract
% motion cycle of an octopus-inspired soft robotic manipulator.
%
% REQUIREMENTS
%   MATLAB R2019b or later (uses 'xline', 'sgtitle')
%   Signal Processing Toolbox (uses 'hann', 'detrend')
%   octopus_tentacle_data.csv  in ../data/   (run generate_data.m first)
%
% OUTPUTS  (saved to ../results/)
%   POD_Mode_Shapes.png
%   Frequency_Spectra.png
%   Temporal_Coefficients.png
%   Validation_Results.png
%
% REFERENCE
%   Sirovich, L. (1987). Turbulence and the dynamics of coherent structures.
%   Quarterly of Applied Mathematics, 45(3), 561–571.

clear; close all; clc;

%% ── PATHS ────────────────────────────────────────────────────────────────────
root_dir = fullfile(fileparts(mfilename('fullpath')), '..');
data_dir = fullfile(root_dir, 'data');
res_dir  = fullfile(root_dir, 'results');
if ~exist(res_dir, 'dir'), mkdir(res_dir); end

data_file = fullfile(data_dir, 'octopus_tentacle_data.csv');
if ~isfile(data_file)
    error(['Data file not found: %s\n''Run generate_data.m first to create it.'], data_file);
end

%% ── 1. LOAD DATA ─────────────────────────────────────────────────────────────
data = readtable(data_file);

frames   = unique(data.frame);
s_values = unique(data.s);

[~, idx]     = unique(data.frame);
times_unique = data.time(idx);
dt           = times_unique(2) - times_unique(1);
fs           = 1 / dt;
time_axis    = times_unique;

% Unit conversion: data stored in metres, all plots in cm
r_scale  = 100;
unit_lbl = 'cm';

% Phase window indices (1-indexed for MATLAB)
idx_ext = 1:40;      % extension   frames  0–39
idx_grp = 41:65;     % grasping    frames 40–64
idx_ret = 66:100;    % retraction  frames 65–99

fprintf('=== DATA SUMMARY ===\n');
fprintf('Frames: %d  |  Spatial stations: %d\n', length(frames), length(s_values));
fprintf('dt = %.4f s  |  fs = %.2f Hz\n', dt, fs);
fprintf('Time range: %.2f – %.2f s\n', min(times_unique), max(times_unique));
fprintf('Freq. resolution: %.3f Hz  |  Nyquist: %.1f Hz\n\n', fs/length(frames), fs/2);

%% 2. RESHAPE INTO TENSOR [N_s × 3 × M]
N_s = length(s_values);
M   = length(frames);
dim = 3;
r   = zeros(N_s, dim, M);

for i = 1:M
    fd = data(data.frame == frames(i), :);
    fd = sortrows(fd, 's');
    r(:,:,i) = [fd.x, fd.y, fd.z];     % keep in metres for POD
end

fprintf('Snapshot tensor: [%d spatial × 3 coords × %d frames]\n\n', N_s, M);

%% 3. RAW DATA VISUALISATION
fig1 = figure('Position', [100, 100, 1200, 400]);

subplot(1,3,1)
plot_idx = [1, 20, 40, 55, 80];
col = lines(length(plot_idx));
for j = 1:length(plot_idx)
    plot3(r(:,1,plot_idx(j))*r_scale, r(:,2,plot_idx(j))*r_scale, r(:,3,plot_idx(j))*r_scale, 'o-', 'Color', col(j,:),'LineWidth', 1.5, 'MarkerSize', 4);
    hold on
end
xlabel(['X (' unit_lbl ')']); ylabel(['Y (' unit_lbl ')']); zlabel(['Z (' unit_lbl ')']);
title('Tentacle motion over time'); grid on; view(3);
legend(arrayfun(@(x) sprintf('t = %.2f s', time_axis(x)), plot_idx, 'UniformOutput', false), 'Location', 'best');

subplot(1,3,2)
pf       = [1, 41, 66];
ph_names = {'Extension', 'Grasping', 'Retraction'};
for j = 1:3
    plot3(r(:,1,pf(j))*r_scale, r(:,2,pf(j))*r_scale, r(:,3,pf(j))*r_scale, 'o-', 'LineWidth', 2, 'MarkerSize', 6,'DisplayName', sprintf('%s (t = %.2f s)', ph_names{j}, time_axis(pf(j))));
    hold on
end
xlabel(['X (' unit_lbl ')']); ylabel(['Y (' unit_lbl ')']); zlabel(['Z (' unit_lbl ')']);
title('Phase snapshots'); legend('Location', 'best'); grid on; view(3);

subplot(1,3,3)
tx = squeeze(r(end,1,:)) * r_scale;
ty = squeeze(r(end,2,:)) * r_scale;
tz = squeeze(r(end,3,:)) * r_scale;
plot3(tx, ty, tz, 'b-', 'LineWidth', 2); hold on
plot3(tx(1),   ty(1),   tz(1),   'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
plot3(tx(41),  ty(41),  tz(41),  'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
plot3(tx(end), ty(end), tz(end), 'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'k');
xlabel(['X (' unit_lbl ')']); ylabel(['Y (' unit_lbl ')']); zlabel(['Z (' unit_lbl ')']);
title('Tip trajectory');
legend('Path', 'Start', 'Grasp', 'End', 'Location', 'best');
grid on; view(3);

sgtitle('Raw centerline data', 'FontSize', 14, 'FontWeight', 'bold');

%% 4. SNAPSHOT POD
%
% Step 1: build snapshot matrix  X  [3N_s × M]
X       = reshape(r, N_s*dim, M);

% Step 2: temporal mean  r_bar(s) = (1/M) sum_k r(s, t_k)
X_mean  = mean(X, 2);

% Step 3: mean-subtracted fluctuations
X_fluct = X - X_mean;

% Step 4: temporal correlation matrix  C_ij = (1/M) integral r'(s,ti)·r'(s,tj) ds
%         Discretised: C = (1/M) * X_fluct' * X_fluct   [M × M]
C = (X_fluct' * X_fluct) / M;

fprintf('=== SNAPSHOT POD ===\n');
fprintf('Snapshot matrix X:       %d DOF × %d snapshots\n', size(X,1), M);
fprintf('Temporal corr. matrix C: %d × %d\n\n', size(C,1), size(C,2));

% Step 5: solve M-dimensional eigenvalue problem  C v_n = lambda_n v_n
[V, D]         = eig(C);
lambda         = diag(D);
[lambda, sIdx] = sort(lambda, 'descend');
V              = V(:, sIdx);

% Step 6: recover spatial modes
%   phi_n(s) = (1/sqrt(lambda_n * M)) * X_fluct * v_n
Phi = X_fluct * V * diag(1 ./ sqrt(lambda * M));

% Step 7: temporal coefficients
%   a_n(t) = phi_n' * X_fluct  =  integral r'(s,t) phi_n(s) ds
a = Phi' * X_fluct;

% Energy partition
lambda_pct = lambda / sum(lambda) * 100;
lambda_cum = cumsum(lambda_pct);

fprintf('EIGENVALUES:\n');
for i = 1:min(6, length(lambda))
    fprintf('  Mode %d:  %6.2f%%   (cumulative: %6.2f%%)\n', i, lambda_pct(i), lambda_cum(i));
end
fprintf('\n');

%% 5. RESHAPE MODES TO SPATIAL DOMAIN
Phi_r    = zeros(N_s, dim, length(lambda));
for n = 1:min(5, length(lambda))
    Phi_r(:,:,n) = reshape(Phi(:,n), N_s, dim);
end
r_mean_r = reshape(X_mean, N_s, dim);

%% 6. FIGURE 1 – POD MODE SHAPES 
fig2 = figure('Position', [100, 100, 1400, 500]);

% Panel A: normalised mode magnitudes vs arc length
subplot(1,3,1)
s_norm   = s_values / max(s_values);
mode_mag = squeeze(sqrt(sum(Phi_r.^2, 2)));
for n = 1:3
    mode_mag(:,n) = mode_mag(:,n) / max(abs(mode_mag(:,n)));
end
plot(s_norm, mode_mag(:,1), 'b-',  'LineWidth', 2.5); hold on
plot(s_norm, mode_mag(:,2), 'r--', 'LineWidth', 2.5)
plot(s_norm, mode_mag(:,3), 'g:',  'LineWidth', 2.5)
xlabel('Normalised arc length s/L', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Normalised mode magnitude',  'FontSize', 12, 'FontWeight', 'bold');
title('First three POD modes',        'FontSize', 14, 'FontWeight', 'bold');
legend('Mode 1 (reaching)', 'Mode 2 (grasping)', 'Mode 3 (fine)', 'Location', 'best', 'FontSize', 11);
grid on; xlim([0 1]);

% Panel B: energy capture bar chart
subplot(1,3,2)
n_show = min(8, length(lambda));
bar(1:n_show, lambda_pct(1:n_show), 'FaceColor', [0.3 0.6 0.9], 'EdgeColor', 'k');
hold on
plot(1:n_show, lambda_cum(1:n_show),'ro-', 'LineWidth', 2.5, 'MarkerSize', 8, 'MarkerFaceColor', 'r');
xlabel('Mode number N',  'FontSize', 12, 'FontWeight', 'bold');
ylabel('Energy (%)',     'FontSize', 12, 'FontWeight', 'bold');
title('Cumulative energy capture', 'FontSize', 14, 'FontWeight', 'bold');
legend('Individual mode', 'Cumulative', 'Location', 'southeast', 'FontSize', 11);
yline(95, 'k--', '95% threshold', 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');
grid on; xlim([0.5, n_show + 0.5]);

% Panel C: mode 1 effect on arm shape (XY projection)
subplot(1,3,3)
[~, t_p] = max( a(1,:));
[~, t_n] = min( a(1,:));
rc_p = (r_mean_r + a(1,t_p) * Phi_r(:,:,1)) * r_scale;
rc_n = (r_mean_r + a(1,t_n) * Phi_r(:,:,1)) * r_scale;
rm   = r_mean_r * r_scale;
plot(rm(:,1),   rm(:,2),   'k-',  'LineWidth', 2,   'DisplayName', 'Mean'); hold on
plot(rc_p(:,1), rc_p(:,2), 'b-',  'LineWidth', 2,   'DisplayName', 'Mode 1: max +');
plot(rc_n(:,1), rc_n(:,2), 'r--', 'LineWidth', 2,   'DisplayName', 'Mode 1: max −');
xlabel(['X (' unit_lbl ')'], 'FontSize', 12, 'FontWeight', 'bold');
ylabel(['Y (' unit_lbl ')'], 'FontSize', 12, 'FontWeight', 'bold');
title('Mode 1 effect on shape', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 11); grid on; axis equal;

sgtitle('Proper orthogonal decomposition results', 'FontSize', 16, 'FontWeight', 'bold');
saveas(fig2, fullfile(res_dir, 'POD_Mode_Shapes.png'));

%% 7. PLOT 2 – PHASE-WINDOWED SPECTRAL ANALYSIS 
%
% Rationale: a_n(t) is non-stationary — each phase produces distinct frequency
% content over a short window (0.5–0.8 s). A global FFT smears the three
% regimes together and recovers only the low-frequency extension ramp.
% Phase-windowed FFT (short-time Fourier transform) isolates the spectral
% signature of each behavioural phase per mode.
%
fig3 = figure('Position', [100, 100, 1400, 700]);

phase_windows = {idx_ext,           idx_grp,             idx_ret};
phase_names   = {'Extension (f 0–39)', 'Grasping (f 40–64)', 'Retraction (f 65–99)'};
ph_colors     = {[0.1 0.6 0.4],     [0.5 0.3 0.8],       [0.85 0.35 0.1]};
f_dom         = zeros(3, 3);    % rows = modes, cols = phases

for n = 1:3
    for p = 1:3
        seg   = a(n, phase_windows{p});
        Mseg  = length(seg);

        % Detrend and apply Hann window to reduce spectral leakage
        seg_d  = detrend(seg);
        win    = hann(Mseg)';
        seg_w  = seg_d .* win;

        % One-sided PSD estimate
        A_fft  = fft(seg_w, Mseg);
        A_fft  = A_fft(1:floor(Mseg/2)+1);
        freq_p = (0:floor(Mseg/2)) * fs / Mseg;
        P      = abs(A_fft).^2 ./ (fs * sum(win.^2) / Mseg);

        % Dominant frequency: search above 1 Hz floor to skip DC artefacts
        fmin_i = find(freq_p >= 1.0, 1);
        if isempty(fmin_i), fmin_i = 2; end
        [~, pk_rel] = max(P(fmin_i:end));
        pk_i        = pk_rel + fmin_i - 1;
        f_dom(n,p)  = freq_p(pk_i);

        subplot(3, 3, (n-1)*3 + p)
        plot(freq_p, P, 'LineWidth', 1.8, 'Color', ph_colors{p}); hold on
        plot(f_dom(n,p), P(pk_i), 'ko', 'MarkerSize', 8, 'LineWidth', 2);
        xlabel('Frequency (Hz)', 'FontSize', 10);
        ylabel('PSD',            'FontSize', 10);
        xlim([0, min(25, fs/2)]);
        grid on;
        title(sprintf('Mode %d  |  %s\nf* = %.1f Hz', n, phase_names{p}, f_dom(n,p)),'FontSize', 10);
    end
end

sgtitle('Phase-windowed power spectral density of a_n(t)', 'FontSize', 14, 'FontWeight', 'bold');
saveas(fig3, fullfile(res_dir, 'Frequency_Spectra.png'));

%% 8. PLOT 3 – TEMPORAL COEFFICIENTS 
fig4 = figure('Position', [100, 100, 1200, 400]);

plot(time_axis, a(1,:), 'b-',  'LineWidth', 2); hold on
plot(time_axis, a(2,:), 'r--', 'LineWidth', 2);
plot(time_axis, a(3,:), 'g:',  'LineWidth', 2);
xlabel('Time (s)',              'FontSize', 12, 'FontWeight', 'bold');
ylabel('Mode amplitude a_n(t)', 'FontSize', 12, 'FontWeight', 'bold');
title('Temporal coefficients vs time', 'FontSize', 14, 'FontWeight', 'bold');
legend('Mode 1 (reaching)', 'Mode 2 (grasping)', 'Mode 3 (fine)','Location', 'best', 'FontSize', 12);
grid on;

% Phase boundary lines — HandleVisibility off prevents phantom legend entries
t_grp = time_axis(idx_grp(1));
t_ret = time_axis(idx_ret(1));
xline(t_grp, 'k--', 'Extension \rightarrow Grasping', 'LabelOrientation', 'horizontal', 'FontSize', 10, 'LineWidth', 1.5, 'HandleVisibility', 'off');
xline(t_ret, 'k--', 'Grasping \rightarrow Retraction', 'LabelOrientation', 'horizontal', 'FontSize', 10, 'LineWidth', 1.5, 'HandleVisibility', 'off');

saveas(fig4, fullfile(res_dir, 'Temporal_Coefficients.png'));

%% 9. RECONSTRUCTION VALIDATION 
N_modes_test = [1, 2, 3, 4, 5];
err          = zeros(length(N_modes_test), 1);
for k = 1:length(N_modes_test)
    N       = N_modes_test(k);
    X_recon = X_mean + Phi(:,1:N) * a(1:N,:);
    err(k)  = norm(X_recon - X, 'fro') / norm(X, 'fro');
end

fprintf('=== RECONSTRUCTION ERRORS ===\n');
for k = 1:length(N_modes_test)
    N = N_modes_test(k);
    fprintf('  N = %d:  error = %.1f%%   captures %.1f%% variance\n',  N, err(k)*100, lambda_cum(N));
end
fprintf('\n');

%% 10. PLOT 4 – VALIDATION 
fig5 = figure('Position', [100, 100, 1200, 500]);

subplot(1,2,1)
plot(N_modes_test, err*100, 'bo-', 'LineWidth', 2.5, 'MarkerSize', 10, 'MarkerFaceColor', 'b');
hold on
plot(3, err(3)*100, 'ro', 'MarkerSize', 15, 'LineWidth', 3);
text(3.15, err(3)*100, sprintf(' N=3: %.1f%% error', err(3)*100), 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Number of modes N',       'FontSize', 12, 'FontWeight', 'bold');
ylabel('Reconstruction error (%)', 'FontSize', 12, 'FontWeight', 'bold');
title('Reconstruction error vs number of modes', 'FontSize', 14, 'FontWeight', 'bold');
grid on; xlim([0.5, 5.5]);

subplot(1,2,2)
fi    = idx_grp(1);
X_r3  = X_mean + Phi(:,1:3) * a(1:3,:);
ro    = reshape(X(:,fi),    N_s, dim) * r_scale;
rr    = reshape(X_r3(:,fi), N_s, dim) * r_scale;
plot3(ro(:,1), ro(:,2), ro(:,3), 'k-',  'LineWidth', 2.5, 'DisplayName', 'Original');
hold on
plot3(rr(:,1), rr(:,2), rr(:,3), 'r--', 'LineWidth', 2.5, 'DisplayName', 'Reconstructed (N=3)');
xlabel(['X (' unit_lbl ')'], 'FontSize', 12, 'FontWeight', 'bold');
ylabel(['Y (' unit_lbl ')'], 'FontSize', 12, 'FontWeight', 'bold');
zlabel(['Z (' unit_lbl ')'], 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('Reconstruction at t = %.2f s (grasping)', time_axis(fi)), 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 11); grid on; view(3);

sgtitle('Validation results', 'FontSize', 16, 'FontWeight', 'bold');
saveas(fig5, fullfile(res_dir, 'Validation_Results.png'));

%% 11. SUMMARY 
fprintf('%s\n', repmat('=', 1, 60));
fprintf('        PROPER ORTHOGONAL DECOMPOSITION RESULTS\n');
fprintf('%s\n', repmat('=', 1, 60));
fprintf('Snapshot matrix:   %d DOF × %d snapshots\n', N_s*dim, M);
fprintf('Sampling rate:     %.2f Hz   (freq. resolution: %.3f Hz)\n', fs, fs/M);
fprintf('Total duration:    %.2f s\n\n', max(time_axis));

fprintf('ENERGY PARTITION:\n');
for i = 1:min(5, length(lambda))
    fprintf('  Mode %d:  %6.2f%%   (cumulative: %6.2f%%)\n', i, lambda_pct(i), lambda_cum(i));
end

fprintf('\nPHASE-WINDOWED DOMINANT FREQUENCIES:\n');
fprintf('  %-8s  %-12s  %-12s  %-12s\n', 'Mode', 'Extension', 'Grasping', 'Retraction');
for n = 1:3
    fprintf('  Mode %-4d  %-12.1f  %-12.1f  %-12.1f  Hz\n', n, f_dom(n,1), f_dom(n,2), f_dom(n,3));
end

fprintf('\nVALIDATION:\n');
fprintf('  3-mode reconstruction error:  %.1f%%\n', err(3)*100);
fprintf('  Variance captured (3 modes):  %.1f%%\n\n', lambda_cum(3));

fprintf('SOFT ROBOTICS DESIGN IMPLICATIONS:\n');
fprintf('  Mode 1  (%5.1f%% energy, ext f* = %.1f Hz):  longitudinal — full length\n', lambda_pct(1), f_dom(1,1));
fprintf('  Mode 2  (%5.1f%% energy, grp f* = %.1f Hz):  bending — distal half\n', lambda_pct(2), f_dom(2,2));
fprintf('  Mode 3  (%5.1f%% energy, ret f* = %.1f Hz):  tip — fine manipulation\n', lambda_pct(3), f_dom(3,3));
fprintf('%s\n', repmat('=', 1, 60));
