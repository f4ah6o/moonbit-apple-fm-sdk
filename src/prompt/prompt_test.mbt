test "ImageAttachment creation with path only" {
  let attachment = ImageAttachment::new("/path/to/image.png")
  assert_eq!(attachment.path, "/path/to/image.png")
  assert_true!(attachment.label.is_empty())
}

test "ImageAttachment creation with path and label" {
  let attachment = ImageAttachment::new(
    "/path/to/image.png",
    label=Some("My image"),
  )
  assert_eq!(attachment.path, "/path/to/image.png")
  assert_eq!(attachment.label, Some("My image"))
}
