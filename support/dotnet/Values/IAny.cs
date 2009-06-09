using Runtime = org.mbarbon.p.runtime.Runtime;
using System.Collections.Generic;

namespace org.mbarbon.p.values
{
    public interface IReferrable
    {
    }

    public interface IAny
    {
        Scalar AsScalar(Runtime runtime);
        string AsString(Runtime runtime);
        int AsInteger(Runtime runtime);
        double AsFloat(Runtime runtime);
        bool AsBoolean(Runtime runtime);
        bool IsDefined(Runtime runtime);

        IAny Assign(Runtime runtime, IAny other);
        IAny AssignIterator(Runtime runtime, IEnumerator<IAny> e);
        IAny ConcatAssign(Runtime runtime, IAny other);

        IAny Clone(Runtime runtime, int depth);

        Code DereferenceSubroutine(Runtime runtime);
    }
}
