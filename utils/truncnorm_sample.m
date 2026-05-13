function x = truncnorm_sample(mu, sigma, a, b, n)
% Sample n values from a truncated normal distribution using rejection.

if nargin < 5
    n = 1;
end

x = mu + sigma .* randn(1, n);
invalid = (x < a) | (x > b);
while any(invalid)
    x(invalid) = mu + sigma .* randn(1, sum(invalid));
    invalid = (x < a) | (x > b);
end
end
