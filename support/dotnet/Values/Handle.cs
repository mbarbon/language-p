using org.mbarbon.p.runtime;
using System.Collections.Generic;

namespace org.mbarbon.p.values
{
    public class P5Handle : IP5Any
    {
        public P5Handle(Runtime runtime)
        {
        }

        public int Write(Runtime runtime, IP5Any scalar, int offset, int length)
        {
            // FIXME cheating
            System.Console.Write(scalar.AsString(runtime));

            return 1;
        }

        // FIXME proper implementation
        public virtual P5Scalar AsScalar(Runtime runtime) { throw new System.NotImplementedException(); }
        public virtual string AsString(Runtime runtime) { throw new System.NotImplementedException(); }
        public virtual int AsInteger(Runtime runtime) { throw new System.NotImplementedException(); }
        public virtual double AsFloat(Runtime runtime) { throw new System.NotImplementedException(); }
        public virtual bool AsBoolean(Runtime runtime) { return true; }
        public virtual bool IsDefined(Runtime runtime) { return true; }

        public virtual IP5Any Clone(Runtime runtime, int depth)
        {
            return new P5Handle(runtime);
        }

        public virtual IP5Any Assign(Runtime runtime, IP5Any other)
        {
            throw new System.NotImplementedException();
        }

        public virtual IP5Any ConcatAssign(Runtime runtime, IP5Any other)
        {
            throw new System.InvalidOperationException();
        }

        public virtual IP5Any AssignIterator(Runtime runtime, IEnumerator<IP5Any> iter)
        {
            return Assign(runtime, iter.MoveNext() ? iter.Current : new P5Scalar(runtime));
        }

        public virtual P5Code DereferenceSubroutine(Runtime runtime)
        {
            throw new System.InvalidOperationException("Not a reference");
        }
    }
}
