using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
namespace WinFormsEFCore.Models;

// Constraint: TClass must be a class and implement IEntity
public interface IEntity
{
    uint Id { get; set; }
}

//Represents C.R.U.D Oprrations with generics
public interface IRepository<T> where T : class
{
    // C - Create
    void Add(T entity);
    void AddRange(IEnumerable<T> entities);

    // R - Read
    T? GetById(uint id);
    IEnumerable<T> GetAll();
    IEnumerable<T> Find(Expression<Func<T, bool>> predicate);

    // U - Update
    void Update(T entity);

    // D - Delete
    void Remove(T entity);
    void RemoveRange(IEnumerable<T> entities);
}

// Base generic repository
public abstract class BaseRepository<TClass>(AppDBContext context) : IRepository<TClass> where TClass : class, IEntity
{
    private readonly AppDBContext _context = context ?? throw new ArgumentNullException(nameof(context));
    private readonly DbSet<TClass> _dbSet = context.Set<TClass>();

    // C - Create
    public virtual void Add(TClass entity)
    {
        _dbSet.Add(entity);
        _context.SaveChanges();
    }

    public virtual void AddRange(IEnumerable<TClass> entities)
    {
        _dbSet.AddRange(entities);
        _context.SaveChanges();
    }

    // R - Read
    public virtual TClass? GetById(uint id)
    {
        return _dbSet
               .AsNoTracking() // Read-only
               .FirstOrDefault(entity => entity.Id == id);
    }

    public virtual IEnumerable<TClass> GetAll()
    {
        return _dbSet
               .AsNoTracking() // Read-only
               .ToList();
    }

    public virtual IEnumerable<TClass> Find(Expression<Func<TClass, bool>> predicate)
    {
        return _dbSet
               .AsNoTracking() // Read-only
               .Where(predicate)
               .ToList();
    }

    // U - Update
    public virtual void Update(TClass entity)
    {
        _dbSet.Update(entity);
        _context.SaveChanges();
    }

    // D - Delete
    public virtual void Remove(TClass entity)
    {
        _dbSet.Remove(entity);
        _context.SaveChanges();
    }

    public virtual void RemoveRange(IEnumerable<TClass> entities)
    {
        _dbSet.RemoveRange(entities);
        _context.SaveChanges();
    }
}