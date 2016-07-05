function [lik, latents] = likfun_gonogo(x,data)
    
    % Likelihood function for Go/NoGo task.
    
    % USAGE: [lik, latents] = likfun_gonogo(x,data)
    %
    % INPUTS:
    %   x - parameters:
    %       x(1) - drift rate go bias weight (b1)
    %       x(2) - drift rate differential action value weight (b2)
    %       x(3) - drift rate Pavlovian bias weight (b3)
    %       x(4) - learning rate for state-action values (alpha)
    %       x(5) - decision threshold (a)
    %   data - structure with the following fields
    %           .c - [N x 1] choices
    %           .r - [N x 1] rewards
    %           .s - [N x 1] states
    %           .rt - [N x 1] response times
    %           .go - [N x 1] go trial indicator (1=Go, 0=NoGo)
    %           .C - number of choice options
    %           .N - number of trials
    %
    % OUTPUTS:
    %   lik - log-likelihood
    %   latents - structure with the following fields:
    %           .v - [N x 1] drift rate
    %
    % Sam Gershman, Nov 2015
    
    % set parameters
    b1 = x(1);          % drift rate go bias weight
    b2 = x(2);          % drift rate differential action value weight
    b3 = x(3);          % drift rate Pavlovian bias weight
    lr = x(4);          % learning rate
    a = x(5);           % decision threshold
    
    % initialization
    lik = 0; C = data.C;
    S = length(unique(data.s)); % number of states
    Q = zeros(S,C);    % initial state-action values
    V = zeros(S,1);    % initial state values
    mx = max(data.rt)+0.1;  % max RT
    
    for n = 1:data.N
        
        % data for current trial
        c = data.c(n);              % choice
        r = data.r(n);              % reward
        go = data.go(n);            % go trial indicator
        s = data.s(n);              % state
        
        % drift rate
        v = b1*go + b2*(Q(s,2)-Q(s,1)) + b3*V(s);
        
        % accumulate log-likelihod
        if data.c(n) == 1 % Go responss
            P = wfpt(data.rt(n),-v,a);  % Wiener first passage time distribution
        else              % NoGo response
            P = integral(@(t) wfpt(t,v,a),0,mx);
        end
        if isnan(P) || P==0; P = realmin; end % avoid NaNs and zeros in the logarithm
        lik = lik + log(P);
        
        % update values
        Q(s,c+1) = Q(s,c+1) + lr*(r - Q(s,c+1));
        V(s) = V(s) + lr*(r-V(s));
        
        % store latent variables
        if nargout > 1
            latents.v(n,1) = v;
        end
        
    end