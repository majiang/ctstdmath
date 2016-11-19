module ctstdmath;

unittest
{
    import std.math;
    enum a = real(1).abs, b = real(1).fabs, c = real(1).sqrt;
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
