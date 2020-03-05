defmodule Sudoku do
  defstruct board: %{rows: %{}, columns: %{}, boxes: %{}},
            line_size: nil,
            numbers: [],
            pointer: {0, 0},
            valid: true

  def check_file(path) do
    File.stream!(path)
    |> Stream.map(&read_sudoku/1)
    |> Stream.run()
  end

  defp read_sudoku(line) do
    {line_size, numbers} = parse_line(line)
    sudoku_struct = %Sudoku{line_size: line_size, numbers: numbers}
    result = Enum.reduce(sudoku_struct.numbers, sudoku_struct, &validate/2)
    # IO.inspect result
    IO.inspect(result.valid)
  end

  defp validate(number, struct) do
    struct
    |> validate_row(number)
    |> validate_col(number)
    |> validate_box(number)
    |> update_pointer
  end

  defp validate_row(struct, number) do
    {_pointer_x, pointer_y} = struct.pointer
    row = struct.board.rows["#{pointer_y}"] || []

    with {:ok, new_row} <- do_validate(row, number) do
      %{
        struct
        | board: %{struct.board | rows: Map.put(struct.board.rows, "#{pointer_y}", new_row)}
      }
    else
      {:error, :found_in_list} ->
        %{struct | valid: false}
    end
  end

  defp validate_col(struct, number) do
    {pointer_x, _pointer_y} = struct.pointer
    column = struct.board.columns["#{pointer_x}"] || []

    with {:ok, new_column} <- do_validate(column, number) do
      %{
        struct
        | board: %{
            struct.board
            | columns: Map.put(struct.board.columns, "#{pointer_x}", new_column)
          }
      }
    else
      {:error, :found_in_list} ->
        %{struct | valid: false}
    end
  end

  defp validate_box(struct, number) do
    {pointer_x, pointer_y} = struct.pointer

    divisor =
      struct.line_size
      |> :math.sqrt()
      |> Kernel.trunc()

    box_x = div(pointer_x, divisor)
    box_y = div(pointer_y, divisor)

    box = struct.board.boxes["#{box_x}#{box_y}"] || []

    with {:ok, new_box} <- do_validate(box, number) do
      %{
        struct
        | board: %{struct.board | boxes: Map.put(struct.board.boxes, "#{box_x}#{box_y}", new_box)}
      }
    else
      {:error, :found_in_list} ->
        %{struct | valid: false}
    end
  end

  defp do_validate(list, number) do
    if number in list do
      {:error, :found_in_list}
    else
      {:ok, [number | list]}
    end
  end

  defp update_pointer(struct) do
    {x_elem, y_elem} = struct.pointer

    {new_x, new_y} =
      cond do
        x_elem < struct.line_size - 1 ->
          {x_elem + 1, y_elem}

        x_elem == struct.line_size - 1 && y_elem == struct.line_size - 1 ->
          {0, 0}

        x_elem == struct.line_size - 1 ->
          {0, y_elem + 1}
      end

    %{struct | pointer: {new_x, new_y}}
  end

  defp parse_line(line) do
    [line_size, sudoku_string] =
      line
      |> String.trim()
      |> String.split(";")

    sudoku_numbers =
      sudoku_string
      |> String.split(",")
      |> Enum.map(&String.to_integer/1)

    {String.to_integer(line_size), sudoku_numbers}
  end
end
