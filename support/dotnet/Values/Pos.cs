using org.mbarbon.p.runtime;

namespace org.mbarbon.p.values
{
    public class P5Pos : P5ActiveScalar
    {
        public P5Pos(Runtime runtime, IP5Any value)
        {
            body = new P5PosBody(runtime, value.AsScalar(runtime));
        }
    }

    public class P5PosBody : P5ActiveScalarBody
    {
        public P5PosBody(Runtime runtime, P5Scalar value)
        {
            Value = value;
        }

        public override void Set(Runtime runtime, IP5Any other)
        {
            var scalar = other.AsScalar(runtime);
            if (!scalar.IsDefined(runtime))
            {
                Value.SetPos(runtime, -1, true);

                return;
            }

            int pos = scalar.AsInteger(runtime);
            int length = Value.Length(runtime);

            if (pos < 0 && -pos >= length)
                pos = 0;
            else if (pos < 0)
                pos = length + pos;
            else if (pos > length)
                pos = length;

            Value.SetPos(runtime, pos, true);
        }

        public override P5Scalar Get(Runtime runtime)
        {
            int pos = Value.GetPos(runtime);

            return pos < 0 ? new P5Scalar(runtime) : new P5Scalar(runtime, pos);
        }

        private P5Scalar Value;
    }
}