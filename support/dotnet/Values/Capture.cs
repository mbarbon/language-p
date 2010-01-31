using org.mbarbon.p.runtime;

namespace org.mbarbon.p.values
{
    public class P5Capture : P5ActiveScalar
    {
        public P5Capture(Runtime runtime, int index)
        {
            body = new P5CaptureBody(runtime, index);
        }
    }

    public class P5CaptureBody : P5ActiveScalarBody
    {
        public P5CaptureBody(Runtime runtime, int index)
        {
            Index = index - 1;
        }

        protected override P5Scalar Get(Runtime runtime)
        {
            if (   runtime.LastMatch.StringCaptures != null
                && Index < runtime.LastMatch.StringCaptures.Length)
                return new P5Scalar(runtime, runtime.LastMatch.StringCaptures[Index]);
            else
                return new P5Scalar(runtime);
        }

        private int Index;
    }
}
