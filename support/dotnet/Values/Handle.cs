using org.mbarbon.p.runtime;
using System.Collections.Generic;

namespace org.mbarbon.p.values
{
    public class Handle : IAny
    {
        public Handle(Runtime runtime)
        {
        }

        public int Write(Runtime runtime, IAny scalar, int offset, int length)
        {
            // FIXME cheating
            System.Console.Write(scalar.AsString(runtime));

            return 1;
        }

        // FIXME proper implementation
        public virtual Scalar AsScalar(Runtime runtime) { throw new System.NotImplementedException(); }
        public virtual string AsString(Runtime runtime) { throw new System.NotImplementedException(); }
        public virtual int AsInteger(Runtime runtime) { throw new System.NotImplementedException(); }
        public virtual double AsFloat(Runtime runtime) { throw new System.NotImplementedException(); }

        public virtual IAny Clone(Runtime runtime, int depth)
        {
            return new Handle(runtime);
        }

        public virtual IAny Assign(Runtime runtime, IAny other)
        {
            throw new System.NotImplementedException();
        }

        public virtual IAny ConcatAssign(Runtime runtime, IAny other)
        {
            throw new System.InvalidOperationException();
        }

        public virtual IAny AssignIterator(Runtime runtime, IEnumerator<IAny> iter)
        {
            return Assign(runtime, iter.MoveNext() ? iter.Current : new Scalar(runtime));
        }
    }
}
