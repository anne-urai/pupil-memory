function readInData_aud

global mypath
addpath('~/Documents/fieldtrip/');
ft_defaults;

%global mypath
subjects    = 1:58;
subjects(ismember(subjects, [13 14 20 51 34])) = [];
% subjects who didn't complete the study: 13, 14, 20 and 51
% subject 34 did not do any of the word blocks, only picturess

% how much of the pupil to read in and visualize?
prestim         = 3;
poststim        = 5;
fsample         = 50; % massively speeds up deconvolution
baselineRange   = [-2 0]; % what time to take for the baseline
dilationRange   = [1 3]; % what time to take for the dilation? stimulus duration

for sj = subjects,
    
    % skip files that already exist
    if exist(sprintf('%s/data/P%02d_aud.mat', mypath, sj), 'file'),
        %  continue;
    end
    
    %% ================================= %
    % BEHAVIOUR: ENCODING, PHASE 1
    %% ================================= %
    
    behavfile = dir(sprintf('%s/data/behaviour/phase1/result/%d*_%s_*.xls', mypath, sj, 'aud'));
    % subject numbers have single precision, filter
    behavfile = behavfile((~cellfun(@isempty, regexp({behavfile(:).name}, sprintf('^%d[a-z]', sj))))).name;
    dat       = readtable(sprintf('%s/data/behaviour/phase1/result/%s', mypath, behavfile));
    
    % rename some variables
    dat.Properties.VariableNames{'Trialnummer'}        = 'trialnr_enc';
    dat.Properties.VariableNames{'Wortnummer'}         = 'word';
    
    %% ================================= %
    % PUPIL: ENCODING, PHASE 1
    %% ================================= %
    
    if exist(sprintf('%s/data/pupil/%02d_d1_%s.txt', mypath, sj, 'aud'), 'file'),
        
        pupil = processPupilData(sprintf('%s/data/pupil/%02d_d1_%s.txt', mypath, sj, 'aud'), ...
            fsample, prestim, poststim);
        print(gcf, '-dpdf', sprintf('%s/preprocfigs/%02d_d1_aud_readinpupil.pdf', mypath, sj));
        
        % remove blinks and saccades
        pupil.dat(:, 1) = blink_regressout(pupil.dat(:, 1), pupil.fsample, ...
            [pupil.blinkoffset pupil.blinkoffset], [pupil.saccoffset pupil.saccoffset], 1, 1);
        print(gcf, '-dpdf', sprintf('%s/preprocfigs/%02d_d1_aud_blinkregress.pdf', mypath, sj));
        
        %% ================================= %
        % MATCH PUPIL TO BEHAVIOURAL DATA
        %% ================================= %
        
        dat.pupil_baseline_enc      = nanmean(pupil.trial(:, ...
            (pupil.trialtime > baselineRange(1) & pupil.trialtime < baselineRange(2))), 2);
        dat.pupil_dilation_enc      = nanmean(pupil.trial(:, ...
            (pupil.trialtime > dilationRange(1) & pupil.trialtime < dilationRange(2))), 2) ...
            - dat.pupil_baseline_enc;
        dat.pupil_timecourse_enc  = pupil.trial;
    else
        dat.pupil_baseline_enc = nan(size(dat.word));
        dat.pupil_dilation_enc = nan(size(dat.word));
        
        pupil.time = -prestim: 1/fsample :poststim;
        dat.pupil_timecourse_enc = nan(length(dat.word), length(pupil.time));
    end
    
    %% ================================= %
    % BEHAVIOUR: PHASE 2, RECOGNITION
    %% ================================= %
    
    behavfile = dir(sprintf('%s/data/behaviour/phase2/result/%d*_%s_*.xls', mypath, sj, 'aud'));
    % subject numbers have single precision, filter
    behavfile = behavfile((~cellfun(@isempty, regexp({behavfile(:).name}, sprintf('^%d[a-z]', sj))))).name;
    dat2 = readtable(sprintf('%s/data/behaviour/phase2/result/%s', mypath, behavfile));
    
    % rename some variables
    dat2.Properties.VariableNames{'Trialnummer'}        = 'trialnr_recog';
    dat2.Properties.VariableNames{'Wortnummer'}         = 'word';
    dat2.Properties.VariableNames{'KorrekteAntwort_0_neu_1_alt_'}        = 'target_oldnew';
    dat2.Properties.VariableNames{'GegebeneAntwort_0_neu_1_alt_'}        = 'recog_oldnew';
    dat2.Properties.VariableNames{'SignalDetection_0_0_0_correctRejection_1_1_1_hit_0_1_2_falseAla'} = 'recog_sdt';
    dat2.Properties.VariableNames{'SicherheitsratingF_r_alte_W_rter_1Bis4_'}  = 'confidence_recog';
    dat2.Properties.VariableNames{'Reaktionszeit_inMs_'}        = 'rt_recog';
    dat2.Properties.VariableNames{'ReaktionszeitF_rSicherheitsrating_inMs_'}        = 'rt_confidence_recog';
    dat2.Properties.VariableNames{'MemoryScore_gegebeneAntwortxSicherheitsrating_ErgibtWertZwische'}        = 'memory_score';
    
    assert(isnan(nanmean(dat2.confidence_recog(dat2.recog_oldnew == 0))), 'mismatch');
    assert(isnan(nanmean(dat2.rt_confidence_recog(dat2.recog_oldnew == 0))), 'mismatch');
    dat2.memory_score(dat2.target_oldnew == 0) = NaN; % do not compute a memory score for new items
    
    %% ================================= %
    % PUPIL: RECOGNITION, PHASE 2
    %% ================================= %
    
    if exist(sprintf('%s/data/pupil/%02d_d2_%s.txt', mypath, sj, 'aud'), 'file'),
        
        pupil = processPupilData(sprintf('%s/data/pupil/%02d_d2_%s.txt', mypath, sj, 'aud'), ...
            fsample, prestim, poststim);
        print(gcf, '-dpdf', sprintf('%s/preprocfigs/%02d_d2_aud_readinpupil.pdf', mypath, sj));
        
        % regress out blinks
        pupil.dat(:, 1) = blink_regressout(pupil.dat(:, 1), pupil.fsample, ...
            [pupil.blinkoffset pupil.blinkoffset], [pupil.saccoffset pupil.saccoffset], 1, 1);
        print(gcf, '-dpdf', sprintf('%s/preprocfigs/%02d_d2_aud_blinkregress.pdf', mypath, sj));
        
        %% ================================= %
        % MATCH PUPIL TO BEHAVIOURAL DATA
        %% ================================= %
        
        dat2.pupil_baseline_recog      = nanmean(pupil.trial(:, ...
            (pupil.trialtime > baselineRange(1) & pupil.trialtime < baselineRange(2))), 2);
        dat2.pupil_dilation_recog      = nanmean(pupil.trial(:, ...
            (pupil.trialtime > dilationRange(1) & pupil.trialtime < dilationRange(2))), 2) ...
            - dat2.pupil_baseline_recog;
        dat2.pupil_timecourse_recog          = pupil.trial;
    else
        dat2.pupil_baseline_recog = nan(size(dat2.word));
        dat2.pupil_dilation_recog = nan(size(dat2.word));
        pupil.time = -prestim: 1/fsample :poststim;
        dat2.pupil_timecourse_recog = nan(length(dat2.word), length(pupil.time));
    end
    
    %% ================================= %
    % BEHAVIOUR: PHASE 2, RECALL
    %% ================================= %
    
    dat3 = readtable(sprintf('%s/data/recall/%02d_Worter.csv', mypath, sj));
    
    vars = dat3.Properties.VariableNames;
    for v = 1:length(vars),
        dat3.Properties.VariableNames{vars{v}} = regexprep(vars{v}, '_*', '_');
    end
    
    dat3.Properties.VariableNames{'x_Wortnummer'}                   = 'word';
    dat3.Properties.VariableNames{'Emotionalit_t_des_Wortes'}       = 'emotional';
    dat3.Properties.VariableNames{'d1_free_recall_remembered'}      = 'recalled_d1';
    dat3.Properties.VariableNames{'d2_free_recall_remembered'}      = 'recalled_d2';
    dat3.Properties.VariableNames{'recognition_correct'}            = 'target_oldnew';
    dat3.Properties.VariableNames{'recognition_response'}           = 'recog_oldnew';
    dat3.Properties.VariableNames{'recognition_signal_detection'}   = 'recog_sdt';
    dat3.Properties.VariableNames{'RT_recognition'}                 = 'rt_recog';
    dat3.Properties.VariableNames{'recognition_certainty_old'}      = 'confidence_recog';
    dat3.Properties.VariableNames{'RT_certainty_rating'}            = 'rt_confidence_recog';
    dat3.memory_score(dat3.target_oldnew == 0) = NaN; % do not compute a memory score for new items
    
    % something weird in the recall variables...
    if any(isnan(dat3.recalled_d1)),
        dat3.recalled_d1(isnan(dat3.recalled_d1)) = 0;
        dat3.recalled_d2(isnan(dat3.recalled_d2)) = 0;
    end
    
    % set recall to 0 for new words
    dat3.recalled_d1(dat3.target_oldnew == 0) = NaN;
    dat3.recalled_d2(dat3.target_oldnew == 0) = NaN;
    
    % remove old pupil values
    dat3(:, strncmp(dat3.Properties.VariableNames, 'pupil', 5)) = [];
    dat3(:, strncmp(dat3.Properties.VariableNames, 'filter', 6)) = [];
    
    % recode RTs to numbers instead of strings
    rt2num = @(x) cellfun(@str2double,x,'un',1);
    if iscell(dat3.rt_confidence_recog),
        dat3.rt_confidence_recog    = rt2num(dat3.rt_confidence_recog);
    end
    if iscell(dat3.rt_recog),
        dat3.rt_recog               = rt2num(dat3.rt_recog);
    end
    dat3(:, strncmp(dat3.Properties.VariableNames, 'rt', 2)) = [];
    
    % remove rows where all entries are empty, duplicate image nrs
    dat3(isnan(nanmean(dat3{:, 2:end}, 2)), :) = [];
    assert(length(unique(dat3.word)) == length(dat3.word), 'trial nr mismatch');
    
    %% ================================= %
    % INTEGRATE ALL OF THOSE INTO 1 FILE
    %% ================================= %
    
    % dont use word nr 98
    dat(dat.word == 98, :)      = [];
    dat2(dat2.word == 98, :)    = [];
    dat3(dat3.word == 98, :)    = [];
    assert(isempty(find(dat3.word == 218)), 'word nr 218 was never presented');
    
    dat4 = outerjoin(dat, dat2, 'keys', {'word'});
    assert(isequaln(dat4.word_dat2(~isnan(dat4.word_dat)), ...
        dat4.word_dat(~isnan(dat4.word_dat))), 'mismatch');
    dat4.Properties.VariableNames{'word_dat2'} = 'word';
    dat4.word_dat = [];
    dat4 = outerjoin(dat4, dat3, 'keys', {'word'});
    assert(isequaln(dat4.word_dat3, dat4.word_dat4), 'mismatch');
    
    % do a few checks & clean up
    dat4 = removeDuplicateVars(dat4, {'confidence_recog', 'word', ...
        'memory_score', 'recog_oldnew', 'recog_sdt','target_oldnew'});
    dat4.subj_idx = sj*ones(size(dat4.word));
    
    % reorder
    dat4 = dat4(:, {'subj_idx', 'word', 'emotional', 'trialnr_enc', 'pupil_baseline_enc', ...
        'pupil_dilation_enc', 'recalled_d1', 'recalled_d2', ...
        'trialnr_recog', 'target_oldnew', 'recog_oldnew', 'rt_recog', ...
        'confidence_recog', 'rt_confidence_recog', 'pupil_baseline_recog', 'pupil_dilation_recog', ...
        'memory_score', ...
        'pupil_timecourse_enc', 'pupil_timecourse_recog'});
    
    % save as a matfile with separate pupil and trialinfo
    pupvars     = strncmp(dat4.Properties.VariableNames', 'pupil', 5);
    puptime     = -prestim: 1/pupil.fsample :poststim;
    pupil       = table2struct(dat4(:, pupvars), 'toscalar', true);
    pupil.time  = puptime;
    
    dat4(:, strncmp(dat4.Properties.VariableNames', 'pupil_timecourse', 16)) = [];
    dat         = dat4;
    savefast(sprintf('%s/data/P%02d_aud.mat', mypath, sj), 'dat', 'pupil');
    
end

% ===================== %
% APPEND over sj
% ===================== %

disp('appending over subjects...');
clearvars -except mypath subjects

alltab = {};
for sj = subjects
    load(sprintf('%s/data/P%02d_aud.mat', mypath, sj));
    allpupil(sj)        = pupil;
    alltab{sj}          = dat;
end
allpupil(cellfun(@isempty, alltab))   = [];
alltab(cellfun(@isempty, alltab))     = [];

% now append
fulltab = cat(1, alltab{:});
fulltab = fulltab(:, [end 1:end-1]);

flds = fieldnames(allpupil(1));
for f = 1:length(flds),
    fullpupil.(flds{f}) = cat(1, allpupil(:).(flds{f}));
end

% save
dat     = fulltab;
pupil   = fullpupil;
savefast(sprintf('%s/data/alldata_aud.mat', mypath), 'dat', 'pupil');

% remove individual files
for sj = subjects,
    delete(sprintf('%s/data/P%02d_aud.mat', mypath, sj));
end
end