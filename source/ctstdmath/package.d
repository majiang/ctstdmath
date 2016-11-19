module ctstdmath;

import std.math : LN2, LOG2E, abs, fabs, sqrt, hypot, poly;
unittest
{
    enum a = real(1).abs, b = real(1).fabs, c = real(1).sqrt, d = real(1).hypot(real(1)), e = real(1).poly([real(0)]);
}
unittest
{
    enum a = real(1).cbrt;
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
    if (x.isNaN)
        return x;
    if (x < -(14).exp2small)
        return 0;
    if (14.exp2small < x)
        return real.infinity;
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
