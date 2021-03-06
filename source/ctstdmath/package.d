module ctstdmath;

import std.math : LN2, LOG2E, PI, PI_2, abs, fabs, sqrt, hypot, poly;
unittest
{
    enum a = real(1).abs, b = real(1).fabs, c = real(1).sqrt, d = real(1).hypot(real(1)), e = real(1).poly([real(0)]);
}
unittest
{
    enum a = real(1).cbrt, b = real(1).exp2, c = real(1).exp, d = real(1).lg, e = real(1).log, f = real(1).expm1;
}

///
real cbrt(in real a)
{
    if (a < 0)
        return -(-a).cbrt;
    if (a.isNaN || a.isInfinity)
        return a;
    if (a == 0)
        return 0;
    // safe initial guess.
    real x = a.sqrt, y = real.infinity;
    while (x < y)
    {
        y = x;
        x = (x * 2 + (a / (x * x))) / 3;
    }
    return x;
}
///
unittest
{
    static assert(8.cbrt == 2);
    static assert(0.cbrt == 0);
    static assert((-8).cbrt == -2);
    static assert(real.nan.cbrt.isNaN);
    static assert(real.infinity.cbrt.isInfinity);
}

/// exponential function.
real exp(real x)
{
    return (x * LOG2E).exp2;
}

/// power of 2.
real exp2(real x)
{
    if (x.isNaN) return x;
    if (x < -(14).exp2small) return 0;
    if (14.exp2small < x) return real.infinity;
    real ret = 1;
    if (0 < x)
    {
        foreach_reverse (byte i; 0..15)
        {
            if (x <= i.exp2small)
                continue;
            x -= i.exp2small;
            ret *= i.exp2exp2;
        }
    }
    else
    {
        foreach_reverse (byte i; 0..15)
        {
            if (-(i.exp2small) <= x)
                continue;
            x += i.exp2small;
            ret /= i.exp2exp2;
        }
    }
    if (ret == 0 || ret == real.infinity)
        return ret;
    if (+0.5 < x)
    {
        x -= 1;
        ret *= 2;
    }
    if (x < -0.5)
    {
        x += 1;
        ret /= 2;
    }
    return (x * LN2).expsmall * ret;
}
///
unittest
{
    static assert(real.nan.exp2.isNaN);
    static assert(real.infinity.exp2.isInfinity);
    static assert((-real.infinity).exp2 == 0);
    static assert(0.exp2 == 1);
    static assert(2.exp2 == 4);
    static assert(8.exp2 == 256);
    static assert((-1).exp2 == 0.5);
}

private auto expsmall(in real x)
in
{
    assert (-1 < x);
    assert (x < +1);
}
body
{
    real ret = 0, nextTerm = 1, old = real.nan;
    size_t i;
    while (ret != old)
    {
        old = ret;
        ret += nextTerm;
        i += 1;
        nextTerm *= x / i;
    }
    return ret;
}

private auto exp2small(byte n)
{
    real ret = 1;
    if (0 <= n)
        foreach (i; 0..n)
            ret *= 2;
    else
        foreach (i; 0..-n)
            ret *= real(0.5);
    return ret;
}
private auto doubling(real x, in ubyte n)
{
    foreach (i; 0..n)
        x *= x;
    return x;
}
private auto exp2exp2(byte n)
{
    return (0 <= n) ? 2.doubling(n) : 0.5.doubling(-n);
}
unittest
{
    static assert(2.exp2small == 4);
    static assert(2.exp2exp2 == 16);
    static assert((-2).exp2small * 4 == 1);
    static assert((-2).exp2exp2 * 16 == 1);
}

/// equivalent to exp(x) - 1, but more accurate when |x| is small.
real expm1(real x)
{
    if (!(-1 < x && x < 1))
        return x.exp - 1;
    real ret = 0, nextTerm = 1, old = real.nan;
    size_t i;
    while (ret != old)
    {
        i += 1;
        nextTerm *= x / i;
        old = ret;
        ret += nextTerm;
    }
    return ret;
}

/// Natural logarithm.
real log(real x)
{
    return x.lg * LN2;
}
alias ln = log; /// ditto

/// Base-2 logarithm.
real lg(real x)
{
    real ret = 0;
    if (x < 0) return real.nan;
    if (x == 0) return -real.infinity;
    if (x.isNaN) return x;
    if (x.isInfinity) return real.infinity; // x = +inf
    enum left = real(2) / 3, right = real(4) / 3;
    if (right < x)
        foreach_reverse (byte i; 0..15)
        {
            if (x / i.exp2exp2 < left)
                continue;
            x /= i.exp2exp2;
            ret += i.exp2small;
        }
    else if (x < left)
        foreach_reverse (byte i; 0..15)
        {
            if (right < i.exp2exp2 * x)
                continue;
            x *= i.exp2exp2;
            ret -= i.exp2small;
        }
    return x.logsmall / LN2 + ret;
}
/// ditto
alias log2 = lg;
unittest
{
    static assert((-1).lg.isNaN);
    static assert(real.infinity.lg.isInfinity);
    static assert(real.nan.lg.isNaN);
    static assert(0.lg < 0 && 0.lg.isInfinity);
    static assert(0.5.lg == -1);
    static assert(1.lg == 0);
    static assert(2.lg == 1);
}

private real logsmall(real x)
in
{
    assert (0.5 < x);
    assert (x < 1.5);
}
body
{
    return log1p(x - 1);
}

/// equivalent to log(x + 1), but more accurate when |x| is small.
real log1p(real x)
{
    real ret = 0, power = -1, old = real.nan;
    size_t i;
    while (ret != old)
    {
        i += 1;
        power *= -x;
        old = ret;
        ret += power / i;
    }
    return ret;
}

/// floor function.
real floor(real x)
{
    if (x.isNaN)
        return x;
    if (x <= -0x1p+63 || +0x1p+63 <= x)
        return x;
    if (x < 0)
        return -(-x).ceil;
    ulong left = 0, right = 1UL << 63;
    // binary search [)
    foreach (i; 0..63)
    {
        auto mid = (left & right) + ((left ^ right) >> 1);
        if (x < mid)
            right = mid;
        else
            left = mid;
    }
    return left;
}
///
unittest
{
    static assert((-0.01).floor == -1);
    static assert(real(0).floor == 0);
    static assert(0.01.floor == 0);
}

/// ceiling function.
real ceil(real x)
{
    if (x.isNaN)
        return x;
    if (x <= -0x1p+63 || +0x1p+63 <= x)
        return x;
    if (x <= 0)
        return -(-x).floor;
    ulong left = 0, right = 1UL << 63;
    // binary search (]
    foreach (i; 0..63)
    {
        auto mid = (left & right) + ((left ^ right) >> 1);
        if (x <= mid)
            right = mid;
        else
            left = mid;
    }
    return right;
}
/// ditto
alias ceiling = ceil;
///
unittest
{
    static assert((-0.01).ceil == 0);
    static assert(real(0).ceil == 0);
    static assert(0.01.ceil == 1);
}

/// reduce x into [-y .. y] modulo 2y.
real modHalf(real x, real y)
{
    if (x.isNaN || y.isNaN || y == 0)
        return real.nan;
    if (y.isInfinity)
        return x;
    if (y < 0)
        return x.modHalf(-y);
    if (x < 0)
        return -(-x).modHalf(y);
    void dfs(real mod)
    {
        if (mod * 2 <= x)
            return dfs(mod * 2);
        if (mod <= x)
            x -= mod;
    }
    dfs(y * 2);
    if (y < x)
        return x - 2 * y;
    return x;
}
///
unittest
{
    static assert(0.modHalf(1) == 0);
    static assert(0.5.modHalf(1) == 0.5);
    static assert(1.modHalf(1) == 1);
    static assert(1.5.modHalf(1) == -0.5);
    static assert(2.modHalf(1) == 0);
    static assert(2.5.modHalf(1) == 0.5);
}

/// cosine.
real cos(real x)
{
    return (x.modHalf(PI) + PI_2).sin;
}
///
unittest
{
    static assert(PI_2.cos == 0);
}

/// sine.
real sin(real x)
{
    x = x.modHalf(PI);
    if (x < 0)
        return -(-x).sin;
    if (PI < x * 2)
        return (PI - x).sin;
    real ret = 0, nextTerm = x, old = real.nan;
    size_t i;
    x = -(x * x);
    while (ret != old)
    {
        old = ret;
        ret += nextTerm;
        i += 2;
        nextTerm *= x / (i * (i + 1));
    }
    return ret;
}
///
unittest
{
    static assert(0.sin == 0);
}

/// tangent.
real tan(real x)
{
    return x.sin / x.cos;
}
/// cotangent.
real cot(real x)
{
    return x.cos / x.sin;
}
/// secant.
real sec(real x)
{
    return 1 / x.cos;
}
/// cosecant.
real csc(real x)
{
    return 1 / x.sin;
}
/// ditto
alias cosec = csc;

/// arctangent.
real atan(real x)
{
    if (x < 0)
        return -(-x).atan;
    if (x.isInfinity)
        return PI_2;
    if (x == 1)
        return PI_2 / 2;
    if (1 < x)
        return PI_2 - (1 / x).atan;
    if (1 < 3 * x * x) // without this, very slow when |x| ~ 1.
        return PI_2 / 3 + ((x - 1 / real(3).sqrt) / (1 + x / real(3).sqrt)).atan;
    real ret = 0, numeratorX = x, old = real.nan;
    x *= x;
    real i = 2;
    while (ret != old)
    {
        old = ret;
        ret += numeratorX * (i + 1 - (i - 1) * x) / (i * i - 1);
        i += 4;
        numeratorX *= x * x;
    }
    import std.experimental.logger;
    i.trace;
    return ret;
}

///
bool isInfinity(real x)
{
    return x < -real.max || real.max < x;
}
///
unittest
{
    static assert(!isInfinity(real.init));
    static assert(!isInfinity(-real.init));
    static assert(!isInfinity(real.nan));
    static assert(!isInfinity(-real.nan));
    static assert(isInfinity(real.infinity));
    static assert(isInfinity(-real.infinity));
    static assert(isInfinity(-1.0L / 0.0L));
    static assert(!isInfinity(real(0)));
}

///
bool isNaN(real x)
{
    return !(0 <= x) && !(x <= 0);
}
///
unittest
{
    static assert(isNaN(real.nan));
    static assert(isNaN(-real.nan));
    static assert(!isNaN(real.infinity));
    static assert(!isNaN(-real.infinity));
    static assert(!isNaN(-1.0L / 0.0L));
    static assert(!isNaN(real(0)));
}
