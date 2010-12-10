using org.mbarbon.p.runtime;

namespace org.mbarbon.p.values
{
    public class P5Substr : P5ActiveScalar
    {
        public P5Substr(Runtime runtime, IP5Any value, int offset)
        {
            body = new P5SubstrBody(runtime, value.AsScalar(runtime),
                                    offset);
        }

        public P5Substr(Runtime runtime, IP5Any value, int offset, int length)
        {
            body = new P5SubstrBody(runtime, value.AsScalar(runtime),
                                    offset, length);
        }
    }

    public class P5SubstrBody : P5ActiveScalarBody
    {
        public P5SubstrBody(Runtime runtime, P5Scalar _value, int _offset)
        {
            value = _value;
            offset = _offset;
            length = null;
        }

        public P5SubstrBody(Runtime runtime, P5Scalar _value, int _offset, int _length)
        {
            value = _value;
            offset = _offset;
            length = _length;
        }

        public override void Set(Runtime runtime, IP5Any other)
        {
            if (length.HasValue)
                value.SpliceSubstring(runtime, offset, length.Value, other);
            else
                value.SpliceSubstring(runtime, offset, other);
        }

        public override P5Scalar Get(Runtime runtime)
        {
            if (length.HasValue)
                return value.Substring(runtime, offset, length.Value);
            else
                return value.Substring(runtime, offset);
        }

        private P5Scalar value;
        private int offset;
        private int? length;
    }
}