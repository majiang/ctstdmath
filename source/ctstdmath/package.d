module ctstdmath;

import std.math : abs, fabs, sqrt;
unittest
{
    enum a = real(1).abs, b = real(1).fabs, c = real(1).sqrt;
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
