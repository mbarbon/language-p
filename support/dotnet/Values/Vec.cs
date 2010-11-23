using org.mbarbon.p.runtime;

namespace org.mbarbon.p.values
{
    public class P5Vec : P5ActiveScalar
    {
        public P5Vec(Runtime runtime, IP5Any value, IP5Any offset, IP5Any bits)
        {
            body = new P5VecBody(runtime, value.AsScalar(runtime),
                                 offset.AsInteger(runtime),
                                 bits.AsInteger(runtime));
        }
    }

    public class P5VecBody : P5ActiveScalarBody
    {
        public P5VecBody(Runtime runtime, P5Scalar _value,
                         int _offset, int _bits)
        {
            value = _value;
            offset = _offset;
            bits = _bits;
        }

        public override bool IsString(Runtime runtime)
        {
            return true;
        }

        public override void Set(Runtime runtime, IP5Any other)
        {
            var str = value.AsString(runtime);
            var bytes = System.Text.Encoding.UTF8.GetBytes(str);
            var intval = other.AsInteger(runtime);

            int byte_offset = (offset * bits) / 8;
            int bit_offset = (offset * bits) % 8;
            int mask = ((1 << bits) - 1);
            int changed = (bytes[byte_offset] & ~(mask << bit_offset)) | ((intval & mask) << bit_offset);

            bytes[byte_offset] = (byte)changed;

            var t = new System.Text.StringBuilder(bytes.Length);

            foreach (byte b in bytes)
                t.Append((char)b);

            value.SetString(runtime, t.ToString());
        }

        public override P5Scalar Get(Runtime runtime)
        {
            var str = value.AsString(runtime);

            int byte_offset = (offset * bits) / 8;
            int bit_offset = (offset * bits) % 8;
            int mask = ((1 << bits) - 1);

            int intval = (str[byte_offset] >> bit_offset) & mask;

            return new P5Scalar(runtime, intval);
        }

        private P5Scalar value;
        private int offset, bits;
    }
}
