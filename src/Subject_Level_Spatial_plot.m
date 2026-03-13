clc
clear
close all
%% Load all the required files for Subject n
% The dataset used in this project is provided by the University of Malta.
% It is not included in this repository.
%
% Please download the dataset from the official source listed in the README.
% After downloading, update the folder path below to match the location of
% the dataset on your local machine.
 
folder = 'PATH_TO_DATASET';
filename1 = 'EOG.mat';
filename2 = 'ControlSignal.mat';
filename3 = 'Target_GA_stream.mat';
load(fullfile(folder,filename1));
load(fullfile(folder,filename2));
load(fullfile(folder,filename3));
Fs = 256; % from data description document
%% ===================== SETUP =====================
HEOG = EOG(1,:) - EOG(2,:);
VEOG = EOG(4,:) - EOG(3,:);

samples_per_trial = 4 * Fs;
num_trials = 200;
fix_win = round(0.14 * Fs); % get the fixation window, where gaze are relatively stable -> used as reference points in affine calibration
%% ===================== Displacement AFFINE CALIBRATION =====================
dEOG_h = zeros(num_trials,1);
dEOG_v = zeros(num_trials,1);
dX = zeros(num_trials,1);
dY = zeros(num_trials,1);

for tr = 1:num_trials
    trial_idx = (tr-1)*4*Fs + 1 : tr*4*Fs;
    cs_trial = ControlSignal(trial_idx);
    % Fixation before saccade
    fix1 = trial_idx(cs_trial==1);
    fix2 = trial_idx(cs_trial==2);
    % Fixation after saccade
    fix1 = fix1(end-fix_win+1:end);
    fix2 = fix2(end-fix_win+1:end);
    % Chang in EOG
    dEOG_h(tr) = mean(HEOG(fix2)) - mean(HEOG(fix1));
    dEOG_v(tr) = mean(VEOG(fix2)) - mean(VEOG(fix1));
    % Gaze displacement (degrees)
    dX(tr) = mean(Target_GA_stream(1,fix2)) - mean(Target_GA_stream(1,fix1));
    dY(tr) = mean(Target_GA_stream(2,fix2)) - mean(Target_GA_stream(2,fix1));
end

% Solve affine (displacement-based)
M = [dX(:), dY(:)];
theta_h = M \ dEOG_h(:);
theta_v = M \ dEOG_v(:);

A = [theta_h(1), theta_h(2);
    theta_v(1), theta_v(2)];

%% ===================== EVALUATION =====================
true_card = zeros(num_trials,1); pred_card = zeros(num_trials,1);
true_quad = zeros(num_trials,1); pred_quad = zeros(num_trials,1);
true_8    = zeros(num_trials,1); pred_8    = zeros(num_trials,1);

GAx = zeros(num_trials,1);
GAy = zeros(num_trials,1);

for tr = 1:num_trials
    t0 = (tr-1)*samples_per_trial + 1;
    sac_idx = t0 : t0 + Fs - 1;

    h = HEOG(sac_idx);
    v = VEOG(sac_idx);

    dh = h(end) - h(1);
    dv = v(end) - v(1);
    dGA = A \ [dh; dv];
    % A_delta is displacement-calibrated matrix
    dx_pred = dGA(1);
    dy_pred = dGA(2);
    GAx = Target_GA_stream(1,sac_idx);
    GAy = Target_GA_stream(2,sac_idx);

    dx_true = GAx(end) - GAx(1);
    dy_true = GAy(end) - GAy(1);
    dx_true_all(tr) = dx_true;
    dy_true_all(tr) = dy_true;
    

    % Classification
    [pred_card_num(tr), pred_quad_num(tr), pred_8_num(tr)] = classify_num(dx_pred, dy_pred);
    [true_card_num(tr), true_quad_num(tr), true_8_num(tr)] = classify_num(dx_true, dy_true);
end
    GAx_endpoints = dx_true_all;
    GAy_endpoints = dy_true_all;
%% ===================== ACCURACY =====================
acc_section_skew = mean(pred_card_num == true_card_num);
acc_section_quad = mean(pred_quad_num == true_quad_num);
acc_section_8    = mean(pred_8_num == true_8_num);

fprintf('Cardinal accuracy: %.2f %%\n', acc_section_skew*100);
fprintf('Quadrant accuracy: %.2f %%\n', acc_section_quad*100);
fprintf('8-class accuracy:  %.2f %%\n', acc_section_8*100);

%% ===================== CONFUSION MATRICES =====================
C_skew = confusionmat(true_card_num, pred_card_num, 'Order', 1:4);
C_quad = confusionmat(true_quad_num, pred_quad_num, 'Order', 1:4);
C_8    = confusionmat(true_8_num,    pred_8_num,    'Order', 1:8);

acc_section_skew = zeros(4,1);
acc_section_quad = zeros(4,1);
acc_section_8    = zeros(8,1);

for i = 1:4
    acc_section_skew(i) = C_skew(i,i) / sum(C_skew(i,:));
    acc_section_quad(i) = C_quad(i,i) / sum(C_quad(i,:));
end

for i = 1:8
    acc_section_8(i) = C_8(i,i) / sum(C_8(i,:));
end


% Compute accuracies
for i=1:4
    acc_section_skew(i) = C_skew(i,i)./sum(C_skew(i,:));
    acc_section_quad(i) = C_quad(i,i)./sum(C_quad(i,:));
end

for i=1:8
    acc_section_8(i) = C_8(i,i)./sum(C_8(i,:));
end

% Print results
fprintf('\nCardinal (Skewed) sectional accuracy:\n');
for i = 1:length(acc_section_skew)
    fprintf('Class %d: %.2f %%\n', i, acc_section_skew(i)*100);
end

fprintf('\n4-Quadrant sectional accuracy:\n');
for i = 1:length(acc_section_quad)
    fprintf('Quadrant %d: %.2f %%\n', i, acc_section_quad(i)*100);
end

fprintf('\n8-Class sectional accuracy:\n');
for i = 1:length(acc_section_8)
    fprintf('Class %d: %.2f %%\n', i, acc_section_8(i)*100);
end



%% ===================== PLOT SPATIAL PLOT =====================
% Matrix of the GA of the endpoints
% % Indices of the 256th sample of each trial 
% endpoint_idx = (0:num_trials-1) * samples_per_trial + Fs; 
% % Extract GAx and GAy endpoints 
% GAx_endpoints = Target_GA_stream(1, endpoint_idx); 
% GAy_endpoints = Target_GA_stream(2, endpoint_idx);
GAx_endpoints = dx_true_all;
GAy_endpoints = dy_true_all;

xmax = max(abs(GAx_endpoints));
xmin = -xmax;
ymax = max(abs(GAy_endpoints));
x_vals = linspace(xmin, xmax, 500);
lim  = max(xmax, ymax);

y1 =  x_vals;    % y = x
y2 = -x_vals;    % y = -x

% spatial plot for skewed
figure(1); hold on
% 1. Correct points
idx1 = (pred_card_num == true_card_num); 
GAx_correct_card = GAx_endpoints(idx1); 
GAy_correct_card = GAy_endpoints(idx1);
scatter(GAx_correct_card,GAy_correct_card, 20, 'green','filled');
% 2. Incorrect points
idx2 = (pred_card_num ~= true_card_num); 
GAx_wrong_card = GAx_endpoints(idx2); 
GAy_wrong_card = GAy_endpoints(idx2);
scatter(GAx_wrong_card,GAy_wrong_card, 20, 'red','filled');
% 3. Boundaries
plot(x_vals, y1, 'k--', 'LineWidth', 1.5);
plot(x_vals, y2, 'k--', 'LineWidth', 1.5);
% 4. Labeling
axis equal;
grid on;
xlim([-lim lim]);
ylim([-lim lim]);
xlabel('Horizontal gaze angle (deg)');
ylabel('Vertical gaze angle (deg)');
title('Spatial distribution of classification accuracy: Skewed Quadrant');
legend('Correct', 'Incorrect');
% 5. quadrant-wise accuracy
text( lim*0.7, 0, sprintf('S1 %.1f%%', acc_section_skew(1)*100))
text( 0, lim*0.7, sprintf('S2 %.1f%%',    acc_section_skew(2)*100), 'HorizontalAlignment','center')
text(-lim*0.7, 0, sprintf('S3 %.1f%%',  acc_section_skew(3)*100))
text( 0,-lim*0.7, sprintf('S4 %.1f%%',  acc_section_skew(4)*100), 'HorizontalAlignment','center')


% spatial plot for 4 quadrant
figure(2); hold on
% 1. Correct points
idx3 = (pred_quad_num == true_quad_num); 
GAx_correct_quad = GAx_endpoints(idx3); 
GAy_correct_quad = GAy_endpoints(idx3);
scatter(GAx_correct_quad,GAy_correct_quad, 20, 'green','filled');
% 2. Incorrect points
idx4 = (pred_quad_num ~= true_quad_num); 
GAx_wrong_quad = GAx_endpoints(idx4); 
GAy_wrong_quad = GAy_endpoints(idx4);
scatter(GAx_wrong_quad,GAy_wrong_quad, 20, 'red','filled');
% 3. Boundaries
xline(0, 'k--', 'LineWidth', 1.5); 
yline(0, 'k--', 'LineWidth', 1.5);
% 4. Labeling
axis equal;
grid on;
xlim([-lim lim]);
ylim([-lim lim]);
xlabel('Horizontal gaze angle (deg)');
ylabel('Vertical gaze angle (deg)');
title('Spatial distribution of classification accuracy: 4 Quadrant');
legend('Correct', 'Incorrect');
% quadrant-wise accuracy
text( lim*0.5,  lim*0.5, sprintf('Q1 %.1f%%', acc_section_quad(1)*100))
text(-lim*0.5,  lim*0.5, sprintf('Q2 %.1f%%', acc_section_quad(2)*100))
text(-lim*0.5, -lim*0.5, sprintf('Q3 %.1f%%', acc_section_quad(3)*100))
text( lim*0.5, -lim*0.5, sprintf('Q4 %.1f%%', acc_section_quad(4)*100))


% spatial plot for 8-class
figure(3); hold on 
% 1. Correct points
idx5 = (pred_8_num == true_8_num); 
GAx_correct_8 = GAx_endpoints(idx5); 
GAy_correct_8 = GAy_endpoints(idx5);
scatter(GAx_correct_8,GAy_correct_8, 20, 'green','filled');
% 2. Incorrect points
idx6 = (pred_8_num ~= true_8_num); 
GAx_wrong_8 = GAx_endpoints(idx6); 
GAy_wrong_8 = GAy_endpoints(idx6);
scatter(GAx_wrong_8,GAy_wrong_8, 20, 'red','filled');
% 3. Boundaries
m1 = tand(22.5);   % ≈ 0.4142
m2 = tand(67.5);   % ≈ 2.4142

plot(x_vals,  m1*x_vals, 'k--', 'LineWidth', 1.5)   % +22.5°
plot(x_vals, -m1*x_vals, 'k--', 'LineWidth', 1.5)   % -22.5°
plot(x_vals,  m2*x_vals, 'k--', 'LineWidth', 1.5)   % +67.5°
plot(x_vals, -m2*x_vals, 'k--', 'LineWidth', 1.5)   % -67.5°

% 4. Labeling
axis equal;
grid on;
xlim([-lim lim]);
ylim([-lim lim]);
xlabel('Horizontal gaze angle (deg)');
ylabel('Vertical gaze angle (deg)');
title('Spatial distribution of classification accuracy: 8 Class');
legend('Correct', 'Incorrect');
% 5. section-wise accuracy
text( lim*0.7,  0, sprintf('S1 %.1f%%', acc_section_8(1)*100))  % Right
text( lim*0.5,  lim*0.5, sprintf('S2 %.1f%%', acc_section_8(2)*100)) % UR
text( 0,  lim*0.7, sprintf('S3 %.1f%%', acc_section_8(3)*100),'HorizontalAlignment','center') % Up
text(-lim*0.6,  lim*0.5, sprintf('S4 %.1f%%', acc_section_8(4)*100)) % UL
text(-lim*0.7,  0, sprintf('S5 %.1f%%', acc_section_8(5)*100)) % Left
text(-lim*0.6, -lim*0.5, sprintf('S6 %.1f%%', acc_section_8(6)*100)) % DL
text( 0, -lim*0.7, sprintf('S7 %.1f%%', acc_section_8(7)*100),'HorizontalAlignment','center') % Down
text( lim*0.5, -lim*0.5, sprintf('S8 %.1f%%', acc_section_8(8)*100)) % DR
%% ===================== CLASSIFIER FUNCTION =====================
% in a separate file (classify_num.m) in this folder

%% ---- Count small-displacement endpoints (< 1 deg from origin) ----
endpoint_dist = sqrt(GAx_endpoints.^2 + GAy_endpoints.^2);
num_small = sum(endpoint_dist < 1);
pct_small = num_small / length(endpoint_dist) * 100;

fprintf('Number of endpoints with displacement < 1 deg: %d (%.2f%%)\n', ...
        num_small, pct_small);
% for S4: Number of endpoints with displacement < 1 deg: 96 (48.00%)
%%% ===== Identify small-displacement endpoints (< 1 deg) =====

% Compute Euclidean distance from origin
endpoint_dist = sqrt(GAx_endpoints.^2 + GAy_endpoints.^2);

% Logical index of small endpoints
idx_small = endpoint_dist < 1;

% Count
num_small = sum(idx_small);
pct_small = num_small / length(endpoint_dist) * 100;

fprintf('\nSmall-displacement endpoints (<1 deg): %d (%.2f%%)\n', ...
        num_small, pct_small);

%% ===== Determine which sectors these small endpoints fall into =====
% Preallocate
small_card = zeros(num_small,1);
small_quad = zeros(num_small,1);
small_8    = zeros(num_small,1);

% Extract the small endpoints
dx_small = GAx_endpoints(idx_small);
dy_small = GAy_endpoints(idx_small);

% Classify each small endpoint
for i = 1:num_small
    [c, q, e] = classify_num(dx_small(i), dy_small(i));
    small_card(i) = c;
    small_quad(i) = q;
    small_8(i)    = e;
end

%% ===== Tabulate results =====

fprintf('\nSmall-endpoint distribution (Cardinal):\n');
tabulate(small_card)

fprintf('\nSmall-endpoint distribution (Quadrant):\n');
tabulate(small_quad)

fprintf('\nSmall-endpoint distribution (8-Class):\n');
tabulate(small_8)

%% find for these low-amplittude saccades how many are classified correct
%% ===================== LOW-AMPLITUDE SACCADE ANALYSIS =====================

% Compute displacement magnitude for each trial
dist = sqrt(dx_true_all.^2 + dy_true_all.^2);

% Logical index for low-amplitude trials (<1 degree)
low_amp = dist < 1;

% Count how many low-amplitude saccades exist
num_low = sum(low_amp);
fprintf('\nTotal low-amplitude saccades (<1°): %d (%.2f %%)\n', ...
        num_low, num_low/num_trials*100);

%% ----- Cardinal -----
num_correct_low_card = sum(pred_card_num(low_amp) == true_card_num(low_amp));
acc_low_card = num_correct_low_card / num_low;

fprintf('\nCardinal classifier:\n');
fprintf('Correct among low-amplitude: %d\n', num_correct_low_card);
fprintf('Accuracy among low-amplitude: %.2f %%\n', acc_low_card*100);

%% ----- Quadrant -----
num_correct_low_quad = sum(pred_quad_num(low_amp) == true_quad_num(low_amp));
acc_low_quad = num_correct_low_quad / num_low;

fprintf('\nQuadrant classifier:\n');
fprintf('Correct among low-amplitude: %d\n', num_correct_low_quad);
fprintf('Accuracy among low-amplitude: %.2f %%\n', acc_low_quad*100);

%% ----- 8-Class -----
num_correct_low_8 = sum(pred_8_num(low_amp) == true_8_num(low_amp));
acc_low_8 = num_correct_low_8 / num_low;

fprintf('\n8-Class classifier:\n');
fprintf('Correct among low-amplitude: %d\n', num_correct_low_8);
fprintf('Accuracy among low-amplitude: %.2f %%\n', acc_low_8*100);
