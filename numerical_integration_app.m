function numerical_integration_app()
% NUMERICAL_INTEGRATION_APP  Interactive midpoint/trapezoid/Simpson integrator.
% Clean state-machine navigation.  Run:  >> numerical_integration_app
%
%   HOME  --[C]--> RECTS --[C]--> METHOD --[1/2/3]--> RESULTS
%     ^             |  ^            |  ^                 |
%     +----[R]------+  +----[B]-----+  +--- (Enter) -----+
%   [H] on METHOD returns Home.   [Q] quits from any screen.
%   [B] on HOME/RECTS = backspace / cross-out individual fields.

    % ---------------- app state ----------------
    S = struct();
    S.fstr  = 'log(x)';
    S.a     = 1;
    S.b     = 2;
    S.n     = 1000;
    S.exact = [];
    S.last  = '';

    state = 'HOME';

    % ---------------- main loop ----------------
    while true
        switch state
            case 'HOME'
                [state, S] = screen_home(S);
            case 'RECTS'
                [state, S] = screen_rects(S);
            case 'METHOD'
                [state, S] = screen_method(S);
            case 'RESULTS'
                [state, S] = screen_results(S);
            case 'QUIT'
                fprintf('Goodbye.\n'); return;
            otherwise
                fprintf('Unknown state "%s". Quitting.\n', state); return;
        end
    end
end

% ======================================================================
%  SCREEN: HOME
% ======================================================================
function [next, S] = screen_home(S)
    clc;
    fprintf('=================================================\n');
    fprintf('  HOME  --  Function & Limits\n');
    fprintf('=================================================\n');
    fprintf('  Function f(x) : %s\n', S.fstr);
    fprintf('  Lower limit a : %s\n', num2str(S.a));
    fprintf('  Upper limit b : %s\n', num2str(S.b));
    fprintf('-------------------------------------------------\n');
    fprintf('  Math functions you may use in f(x):\n');
    fprintf('    sin cos tan asin acos atan sinh cosh tanh\n');
    fprintf('    exp log log10 log2 sqrt abs sign floor ceil round\n');
    fprintf('    pi  e  inf      example:  sin(pi*x) + exp(-x^2)\n');
    fprintf('    operators:  + - * / ^     grouping: ( )\n');
    fprintf('    NOTE: MATLAB log(x) is the NATURAL log (ln).\n');
    fprintf('-------------------------------------------------\n');
    fprintf('  [E] edit f(x)   [L] edit limits   [B] backspace/cross-out\n');
    fprintf('  [C] continue to RECTS             [Q] quit\n');

    cmd = upper(strtrim(ask('HOME> ')));

    switch cmd
        case ''
            next = 'RECTS';               % empty = continue
        case 'E'
            S = edit_function(S);  next = 'HOME';
        case 'L'
            S = edit_limits(S);    next = 'HOME';
        case 'B'
            S = backspace_home(S); next = 'HOME';
        case 'C'
            next = 'RECTS';
        case 'Q'
            next = 'QUIT';
        otherwise
            fprintf('  ! Unknown command.\n');
            pause_enter(); next = 'HOME';
    end
end

% ======================================================================
%  SCREEN: RECTS
% ======================================================================
function [next, S] = screen_rects(S)
    clc;
    fprintf('=================================================\n');
    fprintf('  RECTANGLES  --  number of subintervals n\n');
    fprintf('=================================================\n');
    fprintf('  Function f(x) : %s\n', S.fstr);
    fprintf('  Interval      : [%s , %s]\n', num2str(S.a), num2str(S.b));
    fprintf('  n             : %s\n', num2str(S.n));
    if mod(S.n,2) ~= 0
        fprintf('  (n is ODD -> Simpson will be disabled on next screen)\n');
    end
    fprintf('-------------------------------------------------\n');
    fprintf('  [N] edit n   [B] backspace/cross-out   [R] return Home\n');
    fprintf('  [C] continue to METHOD                 [Q] quit\n');

    cmd = upper(strtrim(ask('RECTS> ')));

    switch cmd
        case ''
            next = 'METHOD';
        case 'N'
            S = edit_n(S);          next = 'RECTS';
        case 'B'
            S = backspace_rects(S); next = 'RECTS';
        case 'R'
            next = 'HOME';
        case 'C'
            next = 'METHOD';
        case 'Q'
            next = 'QUIT';
        otherwise
            fprintf('  ! Unknown command.\n');
            pause_enter(); next = 'RECTS';
    end
end

% ======================================================================
%  SCREEN: METHOD
% ======================================================================
function [next, S] = screen_method(S)
    clc;
    fprintf('=================================================\n');
    fprintf('  METHOD  --  choose integration rule\n');
    fprintf('=================================================\n');
    fprintf('  Function f(x) : %s\n', S.fstr);
    fprintf('  Interval      : [%s , %s]\n', num2str(S.a), num2str(S.b));
    fprintf('  n             : %s\n', num2str(S.n));
    if mod(S.n,2) ~= 0
        fprintf('  !! n is ODD -> Simpson unavailable\n');
    end
    fprintf('-------------------------------------------------\n');
    fprintf('   [1] Midpoint\n');
    fprintf('   [2] Trapezoid\n');
    if mod(S.n,2) == 0
        fprintf('   [3] Simpson\n');
    else
        fprintf('   [3] Simpson   (disabled: n must be even)\n');
    end
    fprintf('   [B] Back to RECTS\n');
    fprintf('   [H] Home\n');
    fprintf('   [Q] Quit\n');
    fprintf('-------------------------------------------------\n');

    cmd = upper(strtrim(ask('METHOD> ')));

    switch cmd
        case '1'
            S.last = 'midpoint';  next = 'RESULTS';
        case '2'
            S.last = 'trapezoid'; next = 'RESULTS';
        case '3'
            if mod(S.n,2) ~= 0
                fprintf('  ! Simpson requires even n. Returning to METHOD.\n');
                pause_enter(); next = 'METHOD';
            else
                S.last = 'simpson'; next = 'RESULTS';
            end
        case 'B'
            next = 'RECTS';
        case 'H'
            next = 'HOME';
        case 'Q'
            next = 'QUIT';
        otherwise
            fprintf('  ! Unknown choice.\n');
            pause_enter(); next = 'METHOD';
    end
end

% ======================================================================
%  SCREEN: RESULTS
% ======================================================================
function [next, S] = screen_results(S)
    % Build function handle
    try
        f = str2func(['@(x) ' S.fstr]);
        f((S.a + S.b)/2);
    catch err
        fprintf('  ! Cannot evaluate f(x): %s\n', err.message);
        pause_enter(); next = 'METHOD'; return;
    end

    a = S.a; b = S.b; n = S.n; h = (b-a)/n;

    % ---- compute ----
    switch S.last
        case 'midpoint'
            x = a + ((1:n) - 0.5) * h;
            val = sum(f(x)) * h;
        case 'trapezoid'
            x = a + (1:n-1) * h;
            val = (f(a) + f(b) + 2*sum(f(x))) * h / 2;
        case 'simpson'
            if mod(n,2) ~= 0
                fprintf('  ! Simpson requires even n.\n');
                pause_enter(); next = 'METHOD'; return;
            end
            xi = a + (1:n-1) * h;
            coeff = 2 * ones(1,n-1);
            coeff(1:2:end) = 4;
            val = (f(a) + f(b) + sum(coeff .* f(xi))) * h / 3;
        otherwise
            fprintf('  ! No method selected.\n');
            pause_enter(); next = 'METHOD'; return;
    end

    clc;
    fprintf('=================================================\n');
    fprintf('  RESULTS  --  %s\n', upper(S.last));
    fprintf('=================================================\n');
    fprintf('  f(x)      = %s\n', S.fstr);
    fprintf('  [a, b]    = [%s , %s]\n', num2str(a), num2str(b));
    fprintf('  n         = %d\n', n);
    fprintf('  Integral  = %.15f\n', val);
    if ~isempty(S.exact)
        fprintf('  Exact     = %.15f\n', S.exact);
        fprintf('  Abs error = %.3e\n', abs(val - S.exact));
    end
    fprintf('-------------------------------------------------\n');

    % optional exact value
    c = upper(strtrim(ask('  Know exact value? [Y]=enter  [N]=skip  [B]=back to METHOD : ')));
    if strcmp(c,'B')
        next = 'METHOD'; return;
    end
    if strcmp(c,'Y')
        se = ask('  exact value : ');
        try
            S.exact = eval_expr(se);
            fprintf('  Exact     = %.15f\n', S.exact);
            fprintf('  Abs error = %.3e\n', abs(val - S.exact));
        catch err
            fprintf('  ! Invalid exact value: %s\n', err.message);
        end
    end

    % optional graph
    c = upper(strtrim(ask('  Show graph? [Y]=yes  [N]=no  [B]=back : ')));
    if strcmp(c,'B')
        next = 'METHOD'; return;
    end
    if ~strcmp(c,'N')
        show_graph(f, a, b, n, S.last, val);
    end

    % navigation after results
    fprintf('-------------------------------------------------\n');
    c = upper(strtrim(ask('  [Enter]=METHOD  [B]=RECTS  [H]=Home  [Q]=quit : ')));
    switch c
        case {'', 'M'}, next = 'METHOD';
        case 'B',       next = 'RECTS';
        case 'H',       next = 'HOME';
        case 'Q',       next = 'QUIT';
        otherwise,      next = 'METHOD';
    end
end

% ======================================================================
%  EDIT HELPERS  (cross-out / backspace in place)
% ======================================================================
function S = edit_function(S)
    fprintf('\n--- Edit f(x) ---\n  current: %s\n', S.fstr);
    new = ask('  new f(x) [Enter=keep, B=back] : ');
    if isempty(strtrim(new)) || strcmpi(strtrim(new),'B'), return; end
    try
        ff = str2func(['@(x) ' new]);
        ff((S.a + S.b)/2);
        S.fstr = new;
        fprintf('  OK: function accepted.\n');
    catch err
        fprintf('  ! Invalid: %s\n  keeping previous.\n', err.message);
    end
    pause_enter();
end

function S = edit_limits(S)
    fprintf('\n--- Edit limits ---\n  current: a=%s b=%s\n', num2str(S.a), num2str(S.b));
    sa = ask('  new a [Enter=keep, B=back] : ');
    if strcmpi(strtrim(sa),'B'), return; end
    if ~isempty(strtrim(sa))
        try, S.a = eval_expr(sa); catch err, fprintf('  ! %s\n',err.message); pause_enter(); return; end
    end
    sb = ask('  new b [Enter=keep, B=back] : ');
    if strcmpi(strtrim(sb),'B'), return; end
    if ~isempty(strtrim(sb))
        try, S.b = eval_expr(sb); catch err, fprintf('  ! %s\n',err.message); pause_enter(); return; end
    end
    if ~(S.b > S.a)
        fprintf('  ! b must exceed a. Reverting b to a+1.\n');
        S.b = S.a + 1;
    end
    fprintf('  OK: a=%s b=%s\n', num2str(S.a), num2str(S.b));
    pause_enter();
end

function S = edit_n(S)
    fprintf('\n--- Edit n ---\n  current: n=%s\n', num2str(S.n));
    sn = ask('  new n (positive integer) [Enter=keep, B=back] : ');
    if strcmpi(strtrim(sn),'B') || isempty(strtrim(sn)), return; end
    v = str2double(sn);
    if isnan(v) || v < 1 || v ~= floor(v)
        fprintf('  ! n must be a positive integer. Reverting.\n');
        pause_enter(); return;
    end
    S.n = v;
    fprintf('  OK: n=%d\n', S.n);
    pause_enter();
end

function S = backspace_home(S)
    fprintf('\n--- Backspace / cross-out (HOME) ---\n');
    fprintf('  [1] reset f(x) to log(x)\n');
    fprintf('  [2] reset a to 1\n');
    fprintf('  [3] reset b to 2\n');
    fprintf('  [B] back\n');
    c = upper(strtrim(ask('  choice : ')));
    switch c
        case '1', S.fstr='log(x)'; fprintf('  reset f(x).\n');
        case '2', S.a=1;           fprintf('  reset a.\n');
        case '3', S.b=2;           fprintf('  reset b.\n');
    end
    pause_enter();
end

function S = backspace_rects(S)
    fprintf('\n--- Backspace / cross-out (RECTS) ---\n');
    fprintf('  [1] reset n to 1000\n');
    fprintf('  [B] back\n');
    c = upper(strtrim(ask('  choice : ')));
    if strcmp(c,'1'), S.n = 1000; fprintf('  reset n.\n'); end
    pause_enter();
end

% ======================================================================
%  GRAPH
% ======================================================================
function show_graph(f, a, b, n, method, val)
    try
        figure('Name', ['Numerical Integration: ' upper(method)], 'NumberTitle','off');
        hold on; grid on;

        xs = linspace(a, b, max(400, 4*n));
        ys = f(xs);
        plot(xs, ys, 'k-', 'LineWidth', 1.5);

        h = (b-a)/n;
        ndraw = min(n, 200);   % cap drawn shapes so plot stays fast

        switch method
            case 'midpoint'
                xm = a + ((1:ndraw) - 0.5) * h;
                ym = f(xm);
                for k = 1:ndraw
                    xl = a + (k-1)*h;
                    rectangle('Position',[xl,0,h,ym(k)], ...
                        'FaceColor',[0.3 0.6 1 0.35], 'EdgeColor','b');
                end
                plot(xm, ym, 'b.', 'MarkerSize', 10);
                title(sprintf('Midpoint, n=%d, \\approx %.10f', n, val));

            case 'trapezoid'
                xs2 = a + (0:ndraw)*h;
                ys2 = f(xs2);
                for k = 1:ndraw
                    patch([xs2(k) xs2(k+1) xs2(k+1) xs2(k)], ...
                          [0 0 ys2(k+1) ys2(k)], ...
                          [1 0.6 0.3], 'FaceAlpha', 0.35, 'EdgeColor','r');
                end
                title(sprintf('Trapezoid, n=%d, \\approx %.10f', n, val));

            case 'simpson'
                nd2 = min(ndraw, 60);
                for i = 1:2:nd2-1
                    x0=a+(i-1)*h; x1=a+i*h; x2=a+(i+1)*h;
                    y0=f(x0); y1=f(x1); y2=f(x2);
                    xq = linspace(x0, x2, 30);
                    L0 = ((xq-x1).*(xq-x2))/((x0-x1)*(x0-x2));
                    L1 = ((xq-x0).*(xq-x2))/((x1-x0)*(x1-x2));
                    L2 = ((xq-x0).*(xq-x1))/((x2-x0)*(x2-x1));
                    yq = y0*L0 + y1*L1 + y2*L2;
                    fill([xq fliplr(xq)], [yq zeros(size(yq))], ...
                         [0.4 0.85 0.4], 'FaceAlpha', 0.25, 'EdgeColor','none');
                end
                title(sprintf('Simpson, n=%d, \\approx %.10f', n, val));
        end

        xlabel('x'); ylabel('f(x)'); xlim([a b]);
        legend('f(x)','Location','best');
        hold off;
    catch err
        fprintf('  ! Could not draw graph: %s\n', err.message);
    end
end

% ======================================================================
%  UTILITIES
% ======================================================================
function s = ask(prompt)
    s = input(prompt, 's');
    if isempty(s), s = ''; end
end

function pause_enter()
    input('  Press Enter to continue...', 's');
end

function v = eval_expr(str)
    v = str2double(str);
    if ~isnan(v), return; end
    f = str2func(['@(pi,e,inf,sqrt,log,log10,log2,exp,sin,cos,tan,' ...
                  'asin,acos,atan,sinh,cosh,tanh,abs) ' str]);
    v = f(pi, exp(1), Inf, @sqrt, @log, @log10, @log2, @exp, ...
          @sin, @cos, @tan, @asin, @acos, @atan, @sinh, @cosh, @tanh, @abs);
end
