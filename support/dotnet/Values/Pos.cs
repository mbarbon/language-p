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
            Value.SetPos(runtime, other.AsInteger(runtime));
        }

        public override P5Scalar Get(Runtime runtime)
        {
            int pos = Value.GetPos(runtime);

            return pos < 0 ? new P5Scalar(runtime) : new P5Scalar(runtime, pos);
        }

        private P5Scalar Value;
    }
}