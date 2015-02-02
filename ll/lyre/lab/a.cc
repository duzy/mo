class IFoo
{
public:
    virtual ~IFoo() {}
    virtual int foo() = 0;
};

class Foo : public IFoo
{
    int value;

public:
    explicit Foo(int v) : value(v) {}
    virtual int foo() { return value; }
};

class Foobar : public IFoo
{
    int value;
    int factor;

public:
    explicit Foobar(int v, int f) : value(v), factor(f) {}
    virtual int foo() { return value * factor; }
};

int main(int argc, char**argv)
{
    Foo foo(1);

    IFoo *ptr1 = new Foo(100);
    IFoo *ptr2 = new Foobar(20, 10);

    int v1 = foo.foo();
    int v2 = ptr1->foo();
    int v3 = ptr2->foo();

    delete ptr1;
    delete ptr2;
    return 0;
}
