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
    IFoo *ptr = new Foo(100);

    int v = ptr->foo();

    delete ptr;
    return 0;
}
