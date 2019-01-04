function [SNR_dB,ber_AF,theo_ber_AF] = main_AF( POW_DIV1 )
%% original definition
    MIN_SNR_dB = 0;   
    MAX_SNR_dB = 12;
    INTERVAL = 0.05;	% SNR interval
    
%     POW_DIV1 = 1/2;  % Power division factor,with cooperation, in order to guarantee a certain power of the total,
                    % respectively, the Source using the 1/2 of the power to send singal to the Relay and Destination
    POW_DIV2 = 1-POW_DIV1;  %   send singal to Destination 
   
    POW = 1;        % without cooperation,Source send signals directly to the Restination with full power
    Monte_MAX=10^2;    % the times of Monte Carlo,Limited to the computer configuration level, select the number to 10

%% (Signal Source) Generate a random binary data stream
    M = 2;       % number of symbols  
    N = 10000;   % number of bits
    %x = randint(1,N,M);	% Random binary data stream %����һ��1*N�ľ��󣬾�����Ԫ��ȡֵ��ΧΪ[0,(M-1)]
    x = randi([0,1],1,N);

%% Modulate using bpsk
    h  = modem.pskmod(2);%����2psk������
    x_s=modulate(h,x);%���Ʋ���Դ�ź�
    %x_s = modulate(modem.pskmod(M),x);	% The signal 'x_s' after bpsk modulation 

%% Rayleigh Fading / Assumed to cross reference channel  %���ú�ε�����˥���ŵ�����һ��ͨ�Ź����У�˥��ϵ������Ϊһ�㶨������ʽ
    H_sd = RayleighCH( 1 );     % between Source and Destination
    H_sr = RayleighCH( 1 );  	% between Source and Relay station
    H_rd = RayleighCH( 1 );     % between Relay station and Destination
    
%% In different SNR in dB
    snrcount = 0;
    
for SNR_dB=MIN_SNR_dB:INTERVAL:MAX_SNR_dB
    
	snrcount = snrcount+1;    % count for different BER under SNR_dB
    
	err_num_SD = 0;  % Used to count the error bit
	err_num_AF = 0;
    
    for tries=0:Monte_MAX
 
        sig = 10^(SNR_dB/10); % SNR, said non-dB
        POW_S1 = POW_DIV1;      % Signal power sr
        POW_S2 = POW_DIV2;      % Signal power rd
        POW_N1 = POW_S1 / sig;  % Noise power sr
        POW_N2 = POW_S2 / sig;  % Noise power rd

    % 'x_s' is transmitted from Source to Relay and Destination
    % AWGN:��ĳһ�ź��м����˹����
        y_sd = awgn( sqrt(POW)*H_sd * x_s, SNR_dB, 'measured');	% Destination received the signal 'y_sd' from Source %'measured'��ʾ�ⶨ�ź�ǿ��
        y_sr = awgn( sqrt(POW_DIV1)*H_sr * x_s, SNR_dB, 'measured');	% Relay received the signal 'y_sr' from Source
      %y = awgn(x,SNR,SIGPOWER) ���SIGPOWER����ֵ�����������dBWΪ��λ���ź�ǿ�ȣ����SIGPOWERΪ'measured'���������ڼ�������֮ǰ�ⶨ�ź�ǿ�ȡ�

    %01:Without Cooperation,Source node transmit the signal to Destination node directly��û��Э��������£�Դ�ڵ�ֱ����Ŀ�ĵؽڵ㷢���ź�
        y_SD = demodulate(modem.pskdemod(M),H_sd'*y_sd);
        err_num_SD = err_num_SD + Act_ber(x,y_SD);   % wrong number of bits without Cooperation   
  
    %02:With Fixed Amplify-and-Forward relaying protocol���ù̶��Ŵ�ת���м�Э�� 
    	% beta: amplification factor
        % x_AF: Relaytransmit the AF signal 'x_AF'
        [beta,x_AF] = AF(H_sr,POW_S2,POW_N2,y_sr);
        y_rd = awgn( sqrt(POW_S2)*H_rd * x_AF, SNR_dB, 'measured');	% Destination received the signal 'y_rd' from Relay
        y_combine_AF = Mrc( H_sd,H_sr,H_rd,beta,POW_S2,POW_N2,POW_S2,POW_N2,y_sd,y_rd);  % MRC
        y_AF = demodulate(modem.pskdemod(M),y_combine_AF); % After demodulate, Destinationthe gains the signal 'y_AF' 
        err_num_AF = err_num_AF + Act_ber(x,y_AF);   % wrong number of bits with AF
   
    end;% for tries=0:Monte_MAX
    
    % Calculated the actual BER for each SNR %ͨ��ͳ�����ؿ��޵�����������ȫ��������Ŀ���Ա�
	ber_SD(snrcount) = err_num_SD/(N*Monte_MAX);	
	ber_AF(snrcount) = err_num_AF/(N*Monte_MAX);
    % Calculated the theoretical BER for each SNR %�����Զ��庯���õ�
    theo_ber_SD(snrcount) = Theo_ber(SNR_dB);
    theo_ber_AF(snrcount) = Theo_ber(H_sd,H_sr,H_rd,POW_S1,POW_N1,POW_S2,POW_N2);     
end;    % for SNR_dB=MIN_SNR_dB:INTERVAL:MAX_SNR_dB

%% draw BER curves 
SNR_dB = MIN_SNR_dB:INTERVAL:MAX_SNR_dB;
% 
% hold on;
% disp('theo_ber_SD=');disp(theo_ber_SD);%disp ������ʾ����
% disp('theo_ber_AF=');disp(theo_ber_AF);
% semilogy(SNR_dB,ber_AF,'-*');%semilogx�ð���������ͼ,x����log10��y�����Եģ�semilogy�ð���������ͼ,y����log10��x�����Ե�
% % legend('AF');              
% grid on; %��������
% ylabel('The AVERAGE BER');
% xlabel('SNR(dB)');
% title('the actual BER of AF');
% axis([MIN_SNR_dB,MAX_SNR_dB,10^(-5),1]);

end



