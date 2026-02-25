using Microsoft.EntityFrameworkCore;

namespace BankApp.Services;


public interface ICRUDService<T> where T : class
{
    Task<IEnumerable<T>> GetAllAsync();
    Task<T?> GetByIdAsync(int id);
    Task<T> CreateAsync(T entity);
    Task<bool> UpdateAsync(int id, T entity);
    Task<bool> DeleteAsync(int id);
}

public class CRUDService<T>(AppDbContext context) : ICRUDService<T> where T : class
{
    public virtual async Task<IEnumerable<T>> GetAllAsync()
        => await context.Set<T>().ToListAsync();

    public virtual async Task<T?> GetByIdAsync(int id)
        => await context.Set<T>().FindAsync(id);

    public virtual async Task<T> CreateAsync(T entity)
    {
        context.Set<T>().Add(entity);
        await context.SaveChangesAsync();
        return entity;
    }

    public virtual async Task<bool> UpdateAsync(int id, T entity)
    {
        // Vi tjekker om entiteten findes før vi opdaterer
        var exists = await context.Set<T>().FindAsync(id);
        if (exists == null) return false;

        context.Entry(exists).CurrentValues.SetValues(entity);
        await context.SaveChangesAsync();
        return true;
    }

    public virtual async Task<bool> DeleteAsync(int id)
    {
        var entity = await context.Set<T>().FindAsync(id);
        if (entity == null) return false;

        context.Set<T>().Remove(entity);
        await context.SaveChangesAsync();
        return true;
    }
}