clc
clear
close all
%% Load all the required files for Subject n (Sn)
% this part is exact the same
folder = ('PATH_TO_DATASET');
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

%% ===================== AFFINE CALIBRATION =====================
EOG_h_cal = [];
EOG_v_cal = [];
X = [];
Y = [];


%%% need to change this: instead of calibating for each trial, calibrate
%%% for each subject with more fixations (eg. 24)
for tr = 1:num_trials
    t0 = (tr-1)*samples_per_trial + 1; % t0: start of each trial

    % Fixation before saccade 1
    fix1_end = t0 + Fs - 1;
    fix1_idx = fix1_end - fix_win + 1 : fix1_end; % so have exact the no. of samples as in fix_win

    % Fixation before saccade 2
    fix2_end = t0 + 2*Fs - 1;
    fix2_idx = fix2_end - fix_win + 1 : fix2_end;

    EOG_h_cal(end+1) = mean(HEOG(fix1_idx));
    EOG_v_cal(end+1) = mean(VEOG(fix1_idx));
    X(end+1) = mean(Target_GA_stream(1,fix1_idx));
    Y(end+1) = mean(Target_GA_stream(2,fix1_idx));

    EOG_h_cal(end+1) = mean(HEOG(fix2_idx));
    EOG_v_cal(end+1) = mean(VEOG(fix2_idx));
    X(end+1) = mean(Target_GA_stream(1,fix2_idx));
    Y(end+1) = mean(Target_GA_stream(2,fix2_idx));
end

M = [X(:), Y(:), ones(length(X),1)];
theta_h = M \ EOG_h_cal(:);
theta_v = M \ EOG_v_cal(:);

A = [theta_h(1), theta_h(2);
     theta_v(1), theta_v(2)];
c = [theta_h(3); theta_v(3)];

%% ===================== EVALUATION =====================
pred_card = strings(num_trials,1);
pred_quad = strings(num_trials,1);
pred_8    = strings(num_trials,1);

true_card = strings(num_trials,1);
true_quad = strings(num_trials,1);
true_8    = strings(num_trials,1);

for tr = 1:num_trials
    t0 = (tr-1)*samples_per_trial + 1;

    % First saccade (0–1 s) 
    sac_idx = t0 : t0 + Fs - 1;

    h = HEOG(sac_idx);
    v = VEOG(sac_idx);

    GAx = Target_GA_stream(1,sac_idx);
    GAy = Target_GA_stream(2,sac_idx);

    % Affine inverse reconstruction (Reconstructed trajectory is in gaze ANGLE space (degrees))
    traj = zeros(length(h),2);
    for i = 1:length(h)
        traj(i,:) = (A \ ([h(i); v(i)] - c))';
    end
    
    % Angular displacement of saccade (degrees)
    dx_pred = traj(end,1) - traj(1,1);
    dy_pred = traj(end,2) - traj(1,2);
    % now added end point averagging
    % dx_pred = mean(traj(end-40:end,1)) - mean(traj(1:10,1));
    % dy_pred = mean(traj(end-40:end,2)) - mean(traj(1:10,2));

    dx_true = GAx(end) - GAx(1);
    dy_true = GAy(end) - GAy(1);

    % Same classifiers for both
    [pred_card_num(tr), pred_quad_num(tr), pred_8_num(tr)] = classify_num(dx_pred, dy_pred);
    [true_card_num(tr), true_quad_num(tr), true_8_num(tr)] = classify_num(dx_true, dy_true);
end

%% ===================== ACCURACY =====================
acc_card = mean(pred_card_num == true_card_num);
acc_quad = mean(pred_quad_num == true_quad_num);
acc_8    = mean(pred_8_num == true_8_num);

fprintf('Cardinal accuracy: %.2f %%\n', acc_card*100);
fprintf('Quadrant accuracy: %.2f %%\n', acc_quad*100);
fprintf('8-class accuracy:  %.2f %%\n', acc_8*100);

C_card = confusionmat(true_card_num, pred_card_num);
C_quad = confusionmat(true_quad_num, pred_quad_num);
C_8    = confusionmat(true_8_num,    pred_8_num);

figure(1);
confusionchart(C_card);
figure(2);
confusionchart(C_quad);
figure(3);
confusionchart(C_8);
