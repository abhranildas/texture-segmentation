load neel_data
close all;
figure;
errorbar(ecc,mean(subject_file.correct,[1 3]),std(mean(subject_file.correct,1),0,3),'-o')
sds = std(mean(subject_file.correct,1),0,3);
xlabel 'eccentricity'
ylabel 'accuracy'