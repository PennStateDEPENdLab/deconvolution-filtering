function [encoding] = deconvolve_Bush_2011(BLDobs,kernel,nev_lr,epsilon)
%
%-Description
% This function deconvolves the BOLD signal using Bush 2011 method
%
%-Inputs
% BLDobs - observed BOLD signal
% kernel - assumed kernel of the BOLD signal
% nev_lr - learning rate for the assignment of neural events
% epsilon - relative error change (termination condition)
%
%-Outputs
% encoding - reconstructed neural events

  %Calc time related to observations
  N = numel(BLDobs);

  %Calc simulation steps related to simulation time
  K = numel(kernel);
  A = K-1+N;
  
  %Termination Params
  preverror = 1E9;
  currerror = 0;

  %Construct activation vector
  activation = zeros(A,1)+(2E-9).*rand(A,1)+(-1E-9);
    
  %Presolve activations to fit target_adjust as encoding
  max_hrf_id_adjust = find(kernel==max(kernel))-1;
  BLDobs_adjust = BLDobs(max_hrf_id_adjust:N);
  pre_encoding = BLDobs_adjust-min(BLDobs_adjust);
  pre_encoding = pre_encoding./max(pre_encoding);
  encoding = pre_encoding;
  activation(K:(K-1+numel(BLDobs_adjust))) = log(pre_encoding./(1-pre_encoding));

  while abs(preverror-currerror) > epsilon

    %Compute encoding vector
    encoding = sigmoid(activation);
    
    %Construct feature space
    feature = generate_feature(encoding,K);

    %Generate virtual bold response
    ytilde = feature(K:size(feature,1),:)*kernel;

    %Convert to percent signal change
    meanCurrent = mean(ytilde);
    brf = ytilde - meanCurrent;
    brf = brf/meanCurrent;
    
    %Compute dEdbrf
    for u=size(brf,2)
        dEdbrf(:,u) = brf(:,u)-BLDobs';
    end

    %Compute dbrfdy
    %dbrfdy = numerical_dbrfdy(ytilde);

    %Compute dEdy
    %dEdy = dbrfdy%*%dEdbrf
    dEdy = dEdbrf;
    
    % dEda = dEdf*dfde*deda
    %      = (dEdf*dfde)*deda
    %      = Dede*deda
    dEde = eye(K)*kernel;
    %back_error = (rep(0,K-1),dEdbrf,rep(0,K-1))
    back_error = [zeros(1,K-1),dEdy',zeros(1,K-1)]; %check concatenation
      
    %Backpropagate Errors
    delta = [];
    for i = 1:A
      active = activation(i);
      deda = dsigmoid(active);
      dEda = dEde.*deda;
      this_error = back_error(i:((i-1)+K));
      delta = [delta,sum(dEda'.*this_error)];
    end

    %Update estimate
    activation = activation-nev_lr.*delta';

    %Iterate Learning
    preverror = currerror;
    currerror = sum(dEdbrf.^2);

    %% [currerror,abs(preverror-currerror)] DEBUG
   
  end

end
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function y = sigmoid(x)
    y=(1./(1+exp(-x)));
end

function y = dsigmoid(x)
    y=(1-sigmoid(x)).*sigmoid(x);
end


function fmatrix = generate_feature(encoding,K)

    encoding = reshape(encoding,numel(encoding),1);
    fmatrix = zeros(numel(encoding),K);
    fmatrix(:,1) = encoding;

    for i = 2:K
        fmatrix(:,i) = [zeros(i-1,1);encoding(1:(numel(encoding)-(i-1)),1)];
    end

end

